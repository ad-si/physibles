-- Bell rest for a saxophone stand (replacement part)
--
-- A C-shaped clip snaps onto the perforated main tube of the stand.
-- Two struts fan out from its sides to a crescent-shaped arm
-- (in the plane perpendicular to the tube, concave side facing away
-- from the tube) which cradles the saxophone. The arm's tips curl
-- forward into two horns, so the bell always rests on those two
-- points regardless of its diameter. A stub on the inside of the
-- clip snaps into one of the holes in the tube and keeps the rest
-- from sliding down.
--
-- Print with the clip axis vertical (as modeled). The crescent arm
-- and the web sit flat on the bed, so no supports are needed.
--
-- All measures in mm

local tube_diameter = 19
local fit_clearance = 0.15 -- Per side, between tube and clip bore

--// Clip
local clip_wall = 3.2
local clip_height = 26
-- Opening of the C between the lip roots, measured at the tube center.
-- The mouth itself is shaped by the lips: each continues the wall
-- tangentially as an arc curving the other way (a smooth S), narrowing
-- into the throat that snaps around the tube before flaring open.
local clip_gap_angle = 100
local clip_edge_radius = 1.2 -- Rounding of the wall's vertical edges
local lip_radius = 6 -- Curvature of the outward-bending lip arc
local lip_sweep = 65 -- How far the lip arc bends away (degrees)
-- Arc over which the edge rounding grows into the fully round lip end
local lip_round_sweep = 20
-- How far the wall's inner face pokes into the bore before the bore is
-- carved out again, turning the rounded face into a flat contact band
local grip_bite = 0.8
-- Arc over which the bite fades out towards the lip roots, so the
-- inner face leaves the bore tangentially instead of with a step
local bite_fade_angle = 15
local stub_protrusion = 6 -- How far the stub reaches into the bore
local stub_base_radius = 4.2 -- Where the stub flares into the clip wall
local stub_tip_radius = 1.6 -- Rounding of the stub's dome tip

--// Crescent arm
local arm_width = 13 -- Radial thickness of the crescent
local arm_height = 24 -- Along the tube axis
local arm_corner_radius = 4.5 -- Rounding of the cross section
local arc_radius = 50 -- Curvature of the crescent's center line
local arc_angle = 60 -- Root-to-root span: 2 * 60 * sin(60/2) = 60
-- Each tip continues tangentially into a tighter arc curling forward
-- (away from the tube), forming two horns, so any bell rests on
-- exactly those two points instead of nesting into the crescent
local horn_radius = 10 -- Curvature of a horn's center line
local horn_sweep = 50 -- Arc a horn adds beyond the crescent (degrees)
-- Each horn ends in a round knob: a vertical cylinder of the arm's
-- half width, its top edge rounded like the arm's top corners, so
-- the nose is a perfect circle in plan view
-- The underside is a V (a keel): a narrow land rests on the bed and
-- two steep faces widen to the full arm width, so no supports are needed
local arm_keel_width = 7 -- Flat land under the keel, at the full section
local arm_keel_edge_radius = 1 -- Rounding of the land's edges
local arm_keel_height = 6 -- Where the V reaches the arm's full width
local arm_side_radius = 1.5 -- Rounding where the V meets the sides

--// Webs between clip and arm: two struts, one per side, like the
--// original part. The middle stays open.
local web_thickness = 6
local web_length = 5 -- From the clip's outer wall to the arm's concave face
local web_clip_angle = 50 -- Around the clip, from the arm direction
local web_arm_angle = 20 -- Along the arm's arc, from its middle

local eps = 0.01 -- Used to prevent z-fighting

--------------------------------------------------------------------------------

local bore_radius = tube_diameter / 2 + fit_clearance
local clip_outer_radius = bore_radius + clip_wall
local z_mid = clip_height / 2

-- Center line of the crescent's middle, measured from the tube axis.
-- The arm sits at +x, the clip opening at -x.
local arm_mid_x = clip_outer_radius + web_length + arm_width / 2
-- The crescent bows towards the clip, concave side facing away from it,
-- so its arc center sits beyond the arm
local arc_center_x = arm_mid_x + arc_radius


-- The C-shaped clip, swept as hulled segments along its wall.
-- The wall follows a circle around the tube; at each end of the
-- opening (at -x) it continues tangentially into an arc curving the
-- other way (the lip). Two tangent arcs form an inherently smooth S:
-- the mouth first narrows into the throat that snaps around the tube,
-- then flares open, ending in fully rounded tips.
local function clip()
  local half_gap = clip_gap_angle / 2
  local mid_radius = bore_radius + clip_wall / 2

  -- Cross section of the wall on the circle,
  -- at `phi` (degrees from the gap center): a pair of vertical columns,
  -- hulled into the wall by the caller. The inner column is biased
  -- into the bore (see `grip_bite`), except near the lip roots.
  local function ring_section(phi)
    local from_end = math.min(phi - half_gap, 360 - half_gap - phi)
    local blend = math.min(1, from_end / bite_fade_angle)
    local bite = grip_bite * blend * blend * (3 - 2 * blend)
    local theta = math.rad(180 + phi)
    local dx, dy = math.cos(theta), math.sin(theta)
    local inner = bore_radius + clip_edge_radius - bite
    local outer = bore_radius + clip_wall - clip_edge_radius
    local column = cylinder { h = clip_height, r = clip_edge_radius, fn = 48 }

    return column:translate(dx * inner, dy * inner, 0)
      + column:translate(dx * outer, dy * outer, 0)
  end

  -- Cross section of the lip, `delta` degrees along its arc
  -- (0 at the root, where it matches ring_section seamlessly).
  -- `side` is 1 for the lip at +y, -1 for the one at -y.
  -- Towards the tip, the edge rounding grows until the two columns
  -- merge into a single fully round one.
  local function lip_section(delta, side)
    local theta_e = 180 + side * half_gap
    local center = mid_radius + lip_radius
    local cx = center * math.cos(math.rad(theta_e))
    local cy = center * math.sin(math.rad(theta_e))
    local along = math.rad(theta_e + side * delta)
    local ux, uy = math.cos(along), math.sin(along)
    local px, py = cx - lip_radius * ux, cy - lip_radius * uy

    local round_blend =
      math.max(0, 1 - (lip_sweep - delta) / lip_round_sweep)
    local edge = clip_edge_radius
      + (clip_wall / 2 - clip_edge_radius) * round_blend * round_blend
    local spread = clip_wall / 2 - edge
    local column = cylinder { h = clip_height, r = edge, fn = 48 }

    return column:translate(px + ux * spread, py + uy * spread, 0)
      + column:translate(px - ux * spread, py - uy * spread, 0)
  end

  -- Walk from one lip tip over the circle to the other tip
  local sections = {}
  for delta = lip_sweep, 0, -2.5 do
    sections[#sections + 1] = lip_section(delta, 1)
  end
  local phi = half_gap
  while phi < 360 - half_gap do
    sections[#sections + 1] = ring_section(phi)
    local from_end = math.min(phi - half_gap, 360 - half_gap - phi)
    phi = phi + (from_end < bite_fade_angle and 3 or 6)
  end
  sections[#sections + 1] = ring_section(360 - half_gap)
  for delta = 0, lip_sweep, 2.5 do
    sections[#sections + 1] = lip_section(delta, -1)
  end

  local result = nil
  for index = 1, #sections - 1 do
    local segment = (sections[index] + sections[index + 1]):hull()
    result = result and (result + segment) or segment
  end
  return result
end


-- Bell-shaped stub on the inside of the clip which reaches through
-- one of the tube's holes: a cosine bell that flares smoothly into
-- the clip wall, necks down to slip through the hole, and ends in a
-- dome inside the tube. The flare nests into the hole's punched dimple.
-- Stacked cone segments (a union, not a hull) preserve the concave
-- flare, and the gentle taper keeps the underside overhang printable
-- with the clip axis vertical.
local function clip_stub()
  local embed = 1 -- Buried in the clip wall to close the seam to the bore
  local length = stub_protrusion + embed - stub_tip_radius
  local steps = 12

  -- Radius along the stub, from the buried base (u = 0) to the dome
  local function radius(u)
    return stub_tip_radius
      + (stub_base_radius - stub_tip_radius)
        * (1 + math.cos(math.pi * u)) / 2
  end

  local stub = sphere { r = stub_tip_radius, fn = 48 }
    :translate(0, 0, length)
  for step = 0, steps - 1 do
    stub = stub + cylinder {
      h = length / steps + eps,
      r1 = radius(step / steps),
      r2 = radius((step + 1) / steps),
      fn = 48,
    }:translate(0, 0, step * length / steps)
  end

  return stub
    :rotate(0, -90, 0)
    :translate(bore_radius + embed, 0, z_mid)
end


-- Two struts from the clip's flanks to the arm, symmetric about the
-- arm direction. Each is a hull of a rounded column buried entirely
-- in the clip wall (the bore cut trims any intrusion), so the strut's
-- sloped top runs straight into the wall without a flat plateau,
-- and one reaching the arm's center line, so it stays fused to the
-- arm despite the arm's receding V faces. Both ends sit on the floor,
-- so the undersides are flat and printable, while the tops fan from
-- the clip's (nearly) full height down to the arm's.
local function web()
  local function strut(side)
    local around = math.rad(side * web_clip_angle)
    local clip_r = clip_outer_radius - web_thickness / 2
    local clip_x = clip_r * math.cos(around)
    local clip_y = clip_r * math.sin(around)
    local along = math.rad(side * web_arm_angle)
    local arm_x = arc_center_x - arc_radius * math.cos(along)
    local arm_y = arc_radius * math.sin(along)

    local arm_column = cylinder {
      h = arm_height - 2,
      r = web_thickness / 2,
      fn = 48,
    }

    return (
      cylinder { h = clip_height - 3, r = web_thickness / 2, fn = 48 }
        :translate(clip_x, clip_y, 0)
      + arm_column:translate(arm_x, arm_y, 0)
    ):hull()
  end

  return strut(1) + strut(-1)
end


-- Cross section of the arm at a point of its center line.
-- `px, py` is the point, `rx, ry` the horizontal unit direction
-- across the arm (perpendicular to the center line).
-- The section stands on the floor and is V-shaped at the bottom:
-- a narrow keel land on the bed, steep V faces widening to the full
-- width at `arm_keel_height`, vertical sides above, and rounded top
-- corners. Hulling two sections yields a segment with these faces.
local function arm_slice(px, py, rx, ry, width, height)
  local radius = math.min(arm_corner_radius, width / 2, height / 2)

  -- The keel land shrinks with the section, so the tips stay V-shaped
  local keel_width = arm_keel_width * width / arm_width
  local keel_offset = math.max(0, keel_width / 2 - arm_keel_edge_radius)
  local side_radius = math.min(arm_side_radius, radius)
  local side_offset = width / 2 - side_radius
  local side_z = math.min(arm_keel_height, height - side_radius)
  local offset_r = width / 2 - radius

  local top = sphere { r = radius, fn = 32 }:translate(0, 0, height - radius)
  local side = sphere { r = side_radius, fn = 32 }:translate(0, 0, side_z)
  local keel = cylinder {
    h = arm_keel_edge_radius,
    r = arm_keel_edge_radius,
    fn = 32,
  }

  local function place(solid, offset)
    return solid:translate(px + rx * offset, py + ry * offset, 0)
  end

  return place(top, offset_r) + place(top, -offset_r)
    + place(side, side_offset) + place(side, -side_offset)
    + place(keel, keel_offset) + place(keel, -keel_offset)
end


-- Point of the arm's center line `dist` mm from the middle, towards
-- +y (side = 1) or -y (side = -1): first along the main arc, then
-- along the horn arc, which continues tangentially with the same
-- sense of curvature, so the tip curls forward. Returns the point
-- and the horizontal across-the-arm unit direction.
local function arm_path_point(side, dist)
  local main_length = arc_radius * math.rad(arc_angle / 2)
  local cx, cy, radius, angle
  if dist <= main_length then
    cx, cy, radius = arc_center_x, 0, arc_radius
    angle = dist / arc_radius
  else
    local root = math.rad(arc_angle / 2)
    cx = arc_center_x - (arc_radius - horn_radius) * math.cos(root)
    cy = (arc_radius - horn_radius) * math.sin(root) * side
    radius = horn_radius
    angle = root + (dist - main_length) / horn_radius
  end
  local rx, ry = -math.cos(angle), math.sin(angle) * side
  return cx + radius * rx, cy + radius * ry, rx, ry
end


-- Distances from the arm's middle (and cross section sizes) at which
-- one half of the arm is sampled: the constant middle coarsely, the
-- tightly curving horn closely. The path ends at the knob's center.
local function arm_half_sections()
  local main_length = arc_radius * math.rad(arc_angle / 2)
  local horn_length = horn_radius * math.rad(horn_sweep)

  local sections = {}
  local mid_steps = 6
  for step = 0, mid_steps do
    sections[#sections + 1] =
      { main_length * step / mid_steps, arm_width, arm_height }
  end

  local horn_steps = 5
  for step = 1, horn_steps do
    sections[#sections + 1] =
      { main_length + horn_length * step / horn_steps, arm_width, arm_height }
  end

  return sections
end


-- The knob capping a horn: a cylinder of the arm's half width around
-- the path's end point, the top edge rounded by a hulled ring of
-- spheres matching the arm's corner rounding. The bottom is chamfered
-- like the arm's keel: it narrows to a land of the keel's width
-- (with the same rounded edge), reaches full width at keel height,
-- and blends into the wall with the arm's side rounding.
local function horn_tip(side, dist)
  local px, py = arm_path_point(side, dist)
  local tip_radius = arm_width / 2
  local ring_radius = tip_radius - arm_corner_radius
  local land_radius = arm_keel_width / 2 - arm_keel_edge_radius
  local side_radius = tip_radius - arm_side_radius

  local knob = cylinder {
    h = arm_height - arm_corner_radius - arm_keel_height,
    r = tip_radius,
    fn = 64,
  }:translate(0, 0, arm_keel_height)
  for step = 0, 23 do
    local around = math.rad(step * 15)
    knob = knob
      + sphere { r = arm_corner_radius, fn = 32 }:translate(
        ring_radius * math.cos(around),
        ring_radius * math.sin(around),
        arm_height - arm_corner_radius
      )
      + sphere { r = arm_side_radius, fn = 16 }:translate(
        side_radius * math.cos(around),
        side_radius * math.sin(around),
        arm_keel_height
      )
      + cylinder {
        h = arm_keel_edge_radius,
        r = arm_keel_edge_radius,
        fn = 16,
      }:translate(
        land_radius * math.cos(around),
        land_radius * math.sin(around),
        0
      )
  end

  return knob:hull():translate(px, py, 0)
end


local function arm()
  local half = arm_half_sections()
  -- The outermost section on each side is skipped: it lies entirely
  -- inside the knob. Instead each knob is hulled with the last kept
  -- section, so the keel chamfer and the sides blend into the knob's
  -- cone and cylinder without a crease.
  local ordered = {}
  for index = #half - 1, 1, -1 do
    ordered[#ordered + 1] = { -1, half[index] }
  end
  for index = 2, #half - 1 do
    ordered[#ordered + 1] = { 1, half[index] }
  end

  local slices = {}
  for index = 1, #ordered do
    local side, entry = ordered[index][1], ordered[index][2]
    local px, py, rx, ry = arm_path_point(side, entry[1])
    slices[index] = arm_slice(px, py, rx, ry, entry[2], entry[3])
  end

  local result = nil
  for index = 1, #slices - 1 do
    local segment = (slices[index] + slices[index + 1]):hull()
    result = result and (result + segment) or segment
  end

  local end_dist = half[#half][1]
  return result
    + (slices[1] + horn_tip(-1, end_dist)):hull()
    + (slices[#slices] + horn_tip(1, end_dist)):hull()
end


-- Carving out the bore flattens the wall's inner face into a flat
-- contact band (see `grip_bite`). The lips bend away from the bore
-- and are never touched by the cut.
-- The stub is added after the cut, so it survives it.
local bore = cylinder { h = clip_height + 2 * eps, r = bore_radius, fn = 96 }
  :translate(0, 0, -eps)
local bell_rest = ((clip() + web() + arm()) - bore) + clip_stub()

-- The part is modeled with the arm along +x;
-- turn it so the arm faces the front (-y) and the opening the back
render(bell_rest:rotate(0, 0, -90))
