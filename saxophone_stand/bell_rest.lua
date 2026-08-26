-- Bell rest for a saxophone stand (replacement part)
--
-- A C-shaped clip snaps onto the perforated main tube of the stand.
-- A fanned web connects it to a crescent-shaped arm
-- (in the plane perpendicular to the tube, concave side facing away
-- from the tube) which cradles the saxophone. A stub on the inside
-- of the clip snaps into one of the holes in the tube
-- and keeps the rest from sliding down.
--
-- Print with the clip axis vertical (as modeled),
-- with supports under the crescent arm.
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
local tube_hole_diameter = 7 -- Holes in the stand's tube
local stub_clearance = 0.5 -- Makes the stub slightly thinner than the holes

--// Crescent arm
local arm_width = 13 -- Radial thickness of the crescent
local arm_height = 17 -- Along the tube axis
local arm_corner_radius = 4.5 -- Rounding of the cross section
local arc_radius = 45 -- Curvature of the crescent's center line
local arc_angle = 115 -- Tip-to-tip span: 2 * 45 * sin(115/2) ~ 76
-- Rounding of the tips: distance from the end, width and height
local arm_tip_sections = {
  { 0.0, 5.0, 7.0 },
  { 1.5, 8.0, 11.0 },
  { 4.0, 11.0, 15.0 },
  { 8.0, arm_width, arm_height },
}

--// Web between clip and arm
local web_thickness = 6
local web_length = 8 -- From the clip's outer wall to the arm's concave face

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


-- Dome-shaped stub on the inside of the clip
-- which snaps into one of the tube's holes.
-- A sphere centered exactly on the bore surface: one half protrudes
-- as a hemisphere, the other half is buried in the clip wall to anchor it.
local function clip_stub()
  local radius = tube_hole_diameter / 2 - stub_clearance
  return sphere { r = radius, fn = 48 }
    :translate(bore_radius, 0, z_mid)
end


-- Fans out from (nearly) the full clip height to the arm's height
local function web()
  return (
    cube { 2, web_thickness, clip_height - 3, center = true }
      :translate(clip_outer_radius - 1, 0, z_mid)
    + cube { 2, web_thickness, arm_height - 2, center = true }
        :translate(arm_mid_x - arm_width / 2 + 1, 0, z_mid)
  ):hull()
end


-- Cross section of the arm at `theta` (degrees along the arc, 0 = middle),
-- as a flat cluster of corner spheres. Hulling two of them
-- yields a segment with rounded edges.
local function arm_slice(theta, width, height)
  local radius = math.min(arm_corner_radius, width / 2, height / 2)
  local t = math.rad(theta)
  -- Radial direction of the arc at theta, pointing away from the arc center
  -- (which sits at +x, so the radial direction leans towards -x)
  local rx, ry = -math.cos(t), math.sin(t)
  local px = arc_center_x + arc_radius * rx
  local py = arc_radius * ry
  local offset_r = width / 2 - radius
  local offset_z = height / 2 - radius
  local corner = sphere { r = radius, fn = 32 }

  return corner:translate(px + rx * offset_r, py + ry * offset_r, z_mid + offset_z)
    + corner:translate(px + rx * offset_r, py + ry * offset_r, z_mid - offset_z)
    + corner:translate(px - rx * offset_r, py - ry * offset_r, z_mid + offset_z)
    + corner:translate(px - rx * offset_r, py - ry * offset_r, z_mid - offset_z)
end


-- Angles (and cross section sizes) at which the arm is sampled:
-- the rounded tips closely, the constant middle coarsely
local function arm_sections()
  local half = arc_angle / 2
  local sections = {}

  for index = 1, #arm_tip_sections do
    local tip = arm_tip_sections[index]
    sections[#sections + 1] =
      { -half + math.deg(tip[1] / arc_radius), tip[2], tip[3] }
  end

  local taper_angle = math.deg(arm_tip_sections[#arm_tip_sections][1] / arc_radius)
  local from = -half + taper_angle
  local to = half - taper_angle
  local mid_steps = 8
  for step = 1, mid_steps - 1 do
    sections[#sections + 1] =
      { from + (to - from) * step / mid_steps, arm_width, arm_height }
  end

  for index = #arm_tip_sections, 1, -1 do
    local tip = arm_tip_sections[index]
    sections[#sections + 1] =
      { half - math.deg(tip[1] / arc_radius), tip[2], tip[3] }
  end

  return sections
end


local function arm()
  local sections = arm_sections()
  local result = nil
  for index = 1, #sections - 1 do
    local a = sections[index]
    local b = sections[index + 1]
    local segment = (
      arm_slice(a[1], a[2], a[3]) + arm_slice(b[1], b[2], b[3])
    ):hull()
    result = result and (result + segment) or segment
  end
  return result
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
