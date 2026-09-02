-- Canon EF rear lens cap.
--
-- A cup that the lens's rear bayonet flange drops into. Its knurled skirt
-- flares out into a wider lip at the open end, for the fingers to twist it
-- by. Inside, three hooks stand off the wall just below the rim: the lens's
-- three bayonet lugs pass between them, and a twist carries each lug in
-- under a hook. The hooks' undersides taper towards their free ends, so a
-- lug enters loosely and is pinched tighter as it turns, and each hook's
-- root is a stop rib that runs down to the floor and ends the twist.
--
-- The hooks sit where the EF lugs are, and those are not evenly spaced.
--
-- The cap is printed on its closed end: the floor is z = 0, the open end
-- faces up.

-- Cup
local floor_thickness = 2.3
local height = 16.3 -- Floor to rim
local bore_radius = 27.275 -- Clears the lens's bayonet flange

-- Skirt: the knurled part of the wall, with square notches cut straight
-- down it
-- Only 1.5 mm of wall is left outside the bore at this radius, so the
-- notches, the chamfer and the hooks' roots are all kept shallower than that
local skirt_radius = 28.75
local skirt_top = 10.5 -- Where the notches end
local notches = 60
local notch_depth = 0.2
local notch_angle = 2 -- Degrees each notch takes up
-- The notches' vertical edges are rounded: the two down in the floor and
-- the two along the ridges both get this radius
local notch_fillet = 0.08
local fillet_facets = 6 -- Segments drawn along each of those arcs

-- Lip: the wall flares out at 45 degrees from a plain band above the notches
-- to a wider rim
local band_top = 10.8 -- Where the flare starts
local lip_radius = 32.5
-- Both outer edges, the skirt's bottom and the rim's top, are broken at
-- 45 degrees by this much
local edge_chamfer = 0.5

-- Hooks: the inner face they present to the lug, the height of their top
-- and their thickness at the root. The underside runs flat from the root for
-- `hook_flat` degrees, then ramps up by `hook_taper` at the free end.
local hook_radius = 25.5
local hook_top = 13.3
local hook_span = 46.91 -- Degrees, rib included
local hook_flat = 18.83
local hook_taper = 0.42
local hook_facets = 48 -- Stations drawn along one hook
-- Where each hook's rib starts, anticlockwise from the +x axis, and how
-- thick the hook is at its root: the middle one is 0.2 mm slimmer, so its
-- lug has a little more room
local hooks = {
  { start = 91.405, thickness = 1.5 },
  { start = 212.337, thickness = 1.3 },
  { start = 336.544, thickness = 1.5 },
}
local rib_span = 7.97 -- Degrees

local segments = 360 -- Facets around every full circle

--------------------------------------------------------------------------------
-- Derived geometry
--------------------------------------------------------------------------------

local wall = skirt_radius - bore_radius
local notch_floor = skirt_radius - notch_depth
local lip_bottom = band_top + (lip_radius - skirt_radius) -- The 45 degree flare
-- Anything grown off the wall or the floor is rooted this far inside them,
-- so unions meet in solid material rather than on a shared face
local root = 0.5
local hook_outer = bore_radius + root
-- The turned cup is a polygon around the axis, and the notches' sides are
-- radial planes. A polygon edge lying in one of those planes trips the
-- boolean, so the cup is turned by half a facet to keep them apart.
local core_twist = 180 / segments

assert(notch_depth < wall, "the notches must not cut through the wall")
assert(
  2 * notch_fillet <= notch_depth,
  "the two fillets have to fit within the notch's depth"
)
assert(
  notch_fillet < skirt_radius * math.rad(notch_angle) / 2,
  "the fillets have to fit within the notch's width"
)
assert(notch_angle < 360 / notches, "the notches need ridges between them")
assert(skirt_top < band_top and lip_bottom < height, "the flare has to fit")
assert(
  edge_chamfer < wall and edge_chamfer < height - lip_bottom,
  "the chamfers have to stay within the wall and the rim"
)
assert(hook_radius < bore_radius, "the hooks have to stand proud of the wall")
assert(hook_flat + 1 < hook_span, "the ramp needs some length")
assert(rib_span < hook_flat, "the rib has to end under the flat part")
assert(root < wall and root < floor_thickness, "the roots must stay buried")
for i = 0, notches - 1 do
  for _, side in ipairs({ -1, 1 }) do
    local edge = i * 360 / notches + side * notch_angle / 2
    local facets = (edge - core_twist) * segments / 360
    assert(
      math.abs(facets - math.floor(facets + 0.5)) > 1e-6,
      "a notch side must not fall on one of the cup's facet edges"
    )
  end
end
for _, hook in ipairs(hooks) do
  assert(
    hook_top - hook.thickness - hook_taper > floor_thickness,
    "a lug has to fit between the floor and the hook"
  )
  assert(hook_top < height, "the hooks have to stay below the rim")
end

--------------------------------------------------------------------------------
-- Parts
--------------------------------------------------------------------------------

-- One notch: a slot cut deeper than the ridges and past the bottom face,
-- so its only faces inside the solid are the two sides and the floor. Its
-- corners are rounded: the floor's corners are convex on the cutter, which
-- leaves fillets in the notch, and at the ridges the sides flare out through
-- an arc tangent to the wall, which rounds the ridges' edges off. The notch
-- is so narrow that its sides can be drawn parallel rather than radial.
local function notch()
  local half_width = skirt_radius * math.rad(notch_angle) / 2
  local outer = skirt_radius + root
  -- One side of the outline, from the floor's middle out past the wall, as
  -- { x, y } with x radial and y across the notch
  local side = { { notch_floor, 0 } }
  local function arc(center, radius, from, to)
    for i = 0, fillet_facets do
      local at = math.rad(from + (to - from) * i / fillet_facets)
      side[#side + 1] = {
        center[1] + radius * math.cos(at),
        center[2] + radius * math.sin(at),
      }
    end
  end
  arc(
    { notch_floor + notch_fillet, half_width - notch_fillet },
    notch_fillet, 180, 90
  )
  arc(
    { skirt_radius - notch_fillet, half_width + notch_fillet },
    notch_fillet, -90, 0
  )
  side[#side + 1] = { outer, half_width + notch_fillet }
  -- Mirror it for the other side, walking back to the floor
  local points = {}
  for i = #side, 1, -1 do
    points[#points + 1] = { side[i][1], -side[i][2] }
  end
  for i = 2, #side do
    points[#points + 1] = side[i]
  end
  return polygon({ points = points })
end

-- The cup: turned in one piece from its profile, then the notches are cut
-- down the skirt and the bore is cut out of the middle. Cutting the notches
-- out of the one solid, rather than wrapping a notched skirt around a core,
-- leaves no shared faces for the union to stumble over.
local function cup()
  local core = polygon({
    points = {
      { 0, 0 },
      { skirt_radius - edge_chamfer, 0 },
      { skirt_radius, edge_chamfer },
      { skirt_radius, band_top },
      { lip_radius, lip_bottom },
      { lip_radius, height - edge_chamfer },
      { lip_radius - edge_chamfer, height },
      { 0, height },
    },
  })
    :rotate_extrude(360, segments)
    :rotate(0, 0, core_twist)
  local notches_outline
  for i = 0, notches - 1 do
    local slot = notch():rotate(i * 360 / notches)
    notches_outline = notches_outline and (notches_outline + slot) or slot
  end
  local slots = notches_outline
    :linear_extrude(skirt_top + root)
    :translate(0, 0, -root)
  local bore = cylinder({
    r = bore_radius, h = height, segments = segments,
  }):translate(0, 0, floor_thickness)
  return core - slots - bore
end

-- A hook and its rib as one solid: a sector swept around the axis between
-- the hook's inner radius and a root inside the wall, flat on top, with an
-- underside that follows `stations` - a list of { angle, bottom } pairs.
-- Two stations at the same angle make a vertical step in the underside.
local function swept_sector(stations)
  local points, faces = {}, {}
  local function point(angle, r, z)
    local a = math.rad(angle)
    points[#points + 1] = { r * math.cos(a), r * math.sin(a), z }
    return #points - 1 -- Faces index from zero
  end
  -- A face given as a loop of corners, fanned into triangles: the side
  -- faces are curved strips, and a polygon face would not be planar
  local function face(...)
    local loop = { ... }
    for i = 2, #loop - 1 do
      faces[#faces + 1] = { loop[1], loop[i], loop[i + 1] }
    end
  end
  -- Four corners per station: inner and outer, bottom and top. A step
  -- shares its top corners with the station before, so nothing degenerates.
  local corners = {}
  for i, station in ipairs(stations) do
    local angle, bottom = station[1], station[2]
    local previous = corners[i - 1]
    local step = previous and previous.angle == angle
    corners[i] = {
      angle = angle,
      inner_bottom = point(angle, hook_radius, bottom),
      outer_bottom = point(angle, hook_outer, bottom),
      inner_top = step and previous.inner_top
        or point(angle, hook_radius, hook_top),
      outer_top = step and previous.outer_top
        or point(angle, hook_outer, hook_top),
    }
  end
  -- Corners are listed clockwise as seen from outside the solid
  local first, last = corners[1], corners[#corners]
  face(first.inner_bottom, first.inner_top, first.outer_top, first.outer_bottom)
  face(last.inner_bottom, last.outer_bottom, last.outer_top, last.inner_top)
  for i = 1, #corners - 1 do
    local a, b = corners[i], corners[i + 1]
    -- The underside, or the step's riser when the two share an angle
    face(a.inner_bottom, a.outer_bottom, b.outer_bottom, b.inner_bottom)
    if a.angle ~= b.angle then
      face(a.inner_top, b.inner_top, b.outer_top, a.outer_top)
      -- Where a step follows, the side faces take in its bottom corner as
      -- well, so the riser's edge is theirs too and nothing is left open
      local c = corners[i + 2]
      if c and c.angle == b.angle then
        face(a.inner_bottom, b.inner_bottom, c.inner_bottom, b.inner_top, a.inner_top)
        face(a.outer_bottom, a.outer_top, b.outer_top, c.outer_bottom, b.outer_bottom)
      else
        face(a.inner_bottom, b.inner_bottom, b.inner_top, a.inner_top)
        face(a.outer_bottom, a.outer_top, b.outer_top, b.outer_bottom)
      end
    end
  end
  return polyhedron({ points = points, faces = faces })
end

-- The underside of a hook, as height against degrees from its start: flat
-- from the root, then the ramp. The rib below the root is handled apart.
local function hook(spec)
  local underside = hook_top - spec.thickness
  local ramp = hook_span - hook_flat
  local function bottom(along)
    if along <= hook_flat then
      return underside
    end
    return underside + hook_taper * (along - hook_flat) / ramp
  end
  -- Stations at an even pitch, with one at each break in the underside.
  -- The rib's end is two stations, the step from the floor up to the hook.
  local pitch = hook_span / hook_facets
  local stations = { { spec.start, floor_thickness - root } }
  local function run(from, to, level)
    local steps = math.ceil((to - from) / pitch)
    for i = 1, steps do
      local along = from + (to - from) * i / steps
      stations[#stations + 1] = { spec.start + along, level(along) }
    end
  end
  run(0, rib_span, function()
    return floor_thickness - root
  end)
  stations[#stations + 1] = { spec.start + rib_span, bottom(rib_span) }
  run(rib_span, hook_flat, bottom)
  run(hook_flat, hook_span, bottom)
  return swept_sector(stations)
end

local function cap()
  local solid = cup()
  for _, spec in ipairs(hooks) do
    solid = solid + hook(spec)
  end
  return solid
end

render(
  cap()
    :color("gray")
    :material("plastic", { roughness = 0.6 })
    :name("canon_ef_lens_cap")
)
