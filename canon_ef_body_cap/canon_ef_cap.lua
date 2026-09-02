-- Canon EF body cap.
--
-- A scalloped disc for the fingers, and on top of it the bayonet: a short
-- flange, a thin ring, and three lips around the ring's top edge that hook
-- behind the camera's mount. Each lip has a stop rib at its leading end. A
-- round bump on the rim marks where the cap lines up with the mount index,
-- and a small blind hole in the disc's top face takes the mount's lock pin.
--
-- The disc's top face is z = 0: the bayonet rises above it and the disc
-- hangs below, with the bore recessed into it as far as a printable floor
-- allows. The cap is printed on its flat bottom, so render() lifts it onto
-- the bed.

-- Disc: the knurled grip. Its wall is drafted, so it is wider at the top,
-- and the scallops are shallow cosine grooves running the full height.
local disc_thickness = 4
-- Across the scallop crests, at the top face. A Canon cap is 65 mm across;
-- this one is wider, to give the fingers more to grip.
local disc_radius = 34
local disc_draft_angle = 5 -- Degrees the wall leans in towards the bottom
local scallops = 50
local scallop_depth = 0.75 -- Crest to trough, at the bottom face
local scallop_facets = 20 -- Points drawn along each scallop

-- Index bump: a round boss on the rim, sitting in a trough, that reaches
-- past the crests. It is a plain cylinder, not drafted like the wall.
local bump_radius = 1.5
local bump_trough = 19 -- Which trough it sits in, counting from the +x axis

-- Floor: the bore runs on down into the disc, leaving this much under it
local floor_thickness = 1.6

-- Bayonet, all radii. The cap fits an EF mount's 54 mm throat.
local bore_radius = 23
local flange_radius = 26.8
local flange_top = 1.5
local ring_radius = 25.15
local ring_top = 5.6
local lip_radius = 26.25
local lip_bottom = 4.2
local lip_top = 5 -- Where the lip's 45 degree lead-in chamfer starts
local lips = 3
local lip_start = 76.875 -- Leading edge of the first lip
local lip_chord = 20 -- The lip's width across the outer radius
local rib_chord = 2 -- ... and the stop rib's

-- Lock pin hole in the disc's top face
local pin_hole_radius = 1.35
local pin_hole_depth = 2
local pin_hole_reach = 30.3 -- Distance from the axis
-- The hole sits this many troughs past the bump, counted clockwise when
-- looking at the flat back of the cap, as measured off a Canon cap
local pin_hole_lead = 7

local segments = 360 -- Facets around every full circle
local hole_segments = 48

--------------------------------------------------------------------------------
-- Derived geometry
--------------------------------------------------------------------------------

local disc_draft = disc_thickness * math.tan(math.rad(disc_draft_angle))
local scallop_pitch = 360 / scallops
local bump_angle = bump_trough * scallop_pitch
local pin_hole_angle = bump_angle + pin_hole_lead * scallop_pitch
local disc_bottom_radius = disc_radius - disc_draft
local floor_depth = disc_thickness - floor_thickness
local disc_scale = disc_radius / disc_bottom_radius
local lip_span = 2 * math.deg(math.asin(lip_chord / 2 / lip_radius))
local rib_span = 2 * math.deg(math.asin(rib_chord / 2 / lip_radius))
local lip_chamfer = lip_radius - (ring_top - lip_top)
-- The lips and ribs are grown out of the middle of the ring's wall, not off
-- its surface, so their union with the ring has no coincident faces to trip
-- over
local lip_root = (bore_radius + ring_radius) / 2

assert(floor_depth > 0, "the floor cannot be thicker than the disc")
assert(
  pin_hole_depth < disc_thickness - 1,
  "the pin hole must not break through the disc's bottom face"
)
assert(bore_radius < ring_radius, "the ring needs a wall")
assert(lip_chamfer > ring_radius, "the chamfer must not cut into the ring")
assert(rib_span < lip_span, "the stop rib has to fit inside its lip")
assert(
  pin_hole_reach - pin_hole_radius > flange_radius
    and pin_hole_reach + pin_hole_radius < disc_bottom_radius - scallop_depth,
  "the pin hole must sit on the flat between flange and rim"
)

--------------------------------------------------------------------------------
-- Parts
--------------------------------------------------------------------------------

-- The disc's outline: a circle whose radius swings with the cosine of the
-- angle, one full swing per scallop, with a trough on the +x axis
local function scalloped_outline(crest_radius)
  local points = {}
  local count = scallops * scallop_facets
  for i = 0, count - 1 do
    local angle = 2 * math.pi * i / count
    local dip = scallop_depth / 2 * (1 + math.cos(scallops * angle))
    local r = crest_radius - dip
    points[#points + 1] = { r * math.cos(angle), r * math.sin(angle) }
  end
  return polygon({ points = points })
end

local function disc()
  local grip = scalloped_outline(disc_bottom_radius)
    :linear_extrude({ h = disc_thickness, scale = disc_scale })
    :translate(0, 0, -disc_thickness)
  local bump = cylinder({
    r = bump_radius, h = disc_thickness, segments = hole_segments,
  })
    :translate(disc_bottom_radius, 0, -disc_thickness)
    :rotate(0, 0, bump_angle)
  return grip + bump
end

-- One lip: a sector around the ring's outside, chamfered along its top edge
-- so it leads into the mount, with the stop rib hanging off its leading end
-- down to the flange. The rib is what is left of a full-height block after
-- the part below the lip is cut away behind the rib: carving one block
-- leaves no seams, where a rib unioned onto the lip would meet it face to
-- face along the outer radius.
local function lip()
  local block = polygon({
    points = {
      { lip_root, flange_top },
      { lip_radius, flange_top },
      { lip_radius, lip_top },
      { lip_chamfer, ring_top },
      { lip_root, ring_top },
    },
  }):rotate_extrude(lip_span, segments)
  -- The cutter starts inside the ring's wall, so the stub it leaves stays
  -- buried in the ring, and it runs on past the block's far end: stopping
  -- on it would leave a zero-thickness fin there
  local overshoot = 1
  local undercut = rect({
    lip_radius + overshoot - lip_root, lip_bottom - flange_top,
  })
    :translate(lip_root, flange_top, 0)
    :rotate_extrude(lip_span - rib_span + overshoot, segments)
    :rotate(0, 0, rib_span)
  return block - undercut
end

local function bayonet()
  local flange = cylinder({
    r = flange_radius, h = flange_top, segments = segments,
  })
  local ring = cylinder({ r = ring_radius, h = ring_top, segments = segments })
  local solid = flange + ring
  for i = 0, lips - 1 do
    solid = solid + lip():rotate(0, 0, lip_start + i * 360 / lips)
  end
  return solid
end

-- The bore is cut last, in one go through the bayonet and on into the disc
local function cap()
  local bore = cylinder({
    r = bore_radius, h = floor_depth + ring_top + 1, segments = segments,
  }):translate(0, 0, -floor_depth)
  local pin_hole = cylinder({
    r = pin_hole_radius, h = pin_hole_depth + 1, segments = hole_segments,
  })
    :translate(pin_hole_reach, 0, -pin_hole_depth)
    :rotate(0, 0, pin_hole_angle)
  return disc() + bayonet() - bore - pin_hole
end

render(
  cap()
    :translate(0, 0, disc_thickness)
    :color("gray")
    :material("plastic", { roughness = 0.6 })
    :name("canon_ef_cap")
)
