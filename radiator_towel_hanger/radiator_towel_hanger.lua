-- Radiator towel hanger: a bracket that hangs a towel rail off the top of a
-- panel radiator, rebuilt as a parametric model from the printed original in
-- radiator-towel-hangers.3mf (printables.com/model/756083).
--
-- The bracket drops over the radiator's top front edge. Its roof rests on the
-- top grill, two prongs hang down behind that edge through the grill - the gap
-- between them straddles one grill bar - and a leg reaches down the front
-- panel to a rounded foot. The rod sits in a closed ring well out in front, so
-- a wet towel hangs clear of the hot panel. The towel's weight tips the
-- bracket forward about the front edge, which presses the foot into the panel
-- and pulls the prongs back against the grill: nothing has to clamp.
--
-- Coordinates: x runs forward, away from the radiator, y runs up, and the flat
-- side profile is extruded along z. The origin sits where the radiator's front
-- face meets its top surface, so every dimension below is measured against one
-- of the two surfaces the bracket actually registers on.

-- Rod and ring. The hole is a plain through hole, not a snap-in C, so the rod
-- is threaded through the hangers before it goes up.
local rod_diameter = var("Rod diameter", 15) -- 20 mm for the thick-rod variant
local rod_fit = 0.2 -- The rod only has to slide, not turn
local ring_wall = 3.9
local rod_hole_radius = (rod_diameter + rod_fit) / 2
local ring_radius = rod_hole_radius + ring_wall
-- Rod axis: far enough forward that a folded towel clears the panel,
-- and low enough that the towel hangs below the top grill's airflow
local rod_reach = 58
local rod_drop = 9

-- Print orientation: the side profile lies in the print plane, so every
-- overhang is a bridge and the part needs no supports. The width is the
-- z height of the print.
local part_width = 18
local edge_chamfer = 0.4 -- Breaks the first-layer and top edges
local chamfer_tip = 0.02 -- Flat left on the bevel cone, see hanger()
local chamfer_segments = 24 -- Facets around that cone, see hanger()

-- Radiator interface, all measured off the original.
-- The prong gap is the one number that has to match the radiator: 4.6 mm here
-- (the original's V2), 4.0 mm on the first version's thinner grills.
local grill_bar = 4.6
local relief_depth = 2.751 -- The panel's top edge rolls back by this much
local relief_height = 9.301 -- ... over this much of the panel's height
local roof_fillet = 1 -- Where the roof turns down into the relief
-- ... and the smaller roundings the rest of the notch turns through: the roof
-- onto the prongs' front face, and both corners of the ledge
local notch_fillet = 0.6
local prong_back = 11.07 -- Prongs' front face, behind the panel face
local prong_tip = { -17.09, -36.887 } -- Centre of the prongs' rounded tip
local prong_tip_radius = 3.145
-- The prongs' back face is the nose cap's other common tangent, so the whole
-- back of the bracket is one surface that slides down past the grill's edge

-- Nose: the block over the radiator's top edge, spanned by a big cap circle
-- at the back and a smaller shoulder circle at the front. Their common
-- tangent is the flat top, and the shoulder rolls that top down towards the
-- arm.
local nose_top = 7
local cap_radius = 11.5
local cap_x = -11.07
local shoulder_radius = 8.355
local shoulder_x = -0.54

-- Arm: the straight beam from the nose out to the ring
local arm_top = -5
local arm_bottom = -9.771

-- Leg and foot: a flat band down the radiator's front face, ending in a
-- rounded foot that is the bracket's only load-bearing contact with the panel
local band = 6 -- Thickness of the leg and of the strut
local foot_radius = 6.501
local foot_y = -45.36

-- Strut: a curved band of the same thickness from the foot up into the ring,
-- carrying the rod's load back down to the foot. Both its edges are circles
-- about a centre far below and in front of the bracket.
local strut_center = { 61.05, -74.58 }
local strut_radius = 58.44 -- Centreline
local strut_thickness = band

-- Fillet radii, one for each place two of those faces meet. The first three
-- round the outline itself; the last four round the corners of the triangular
-- window between arm, leg, strut and ring.
local nose_arm_fillet = 12
local arm_ring_fillet = 10.301
local strut_ring_fillet = 11.311
local window_arm_leg_fillet = 12
local window_arm_ring_fillet = 2.118
local window_strut_ring_fillet = 2.02
local window_strut_leg_fillet = 2.484

local hole_segments = 96 -- The rod hole, the one circle still drawn as one
local arc_chord = 0.6 -- Longest chord any arc in the outline is drawn with
local arc_step = 4 -- ... and the widest angle, in degrees

--------------------------------------------------------------------------------
-- Derived geometry and the design rules that fix it
--------------------------------------------------------------------------------

local rod_center = { rod_reach, -rod_drop }
-- Both nose circles hang from the flat top, so it is their common tangent
local cap_center = { cap_x, nose_top - cap_radius }
local shoulder_center = { shoulder_x, nose_top - shoulder_radius }
local foot_center = { foot_radius, foot_y }
local prong_gap = grill_bar
local prong_wall = (part_width - prong_gap) / 2
local strut_window_radius = strut_radius + strut_thickness / 2
local strut_outer_radius = strut_radius - strut_thickness / 2

assert(prong_wall >= 2, "each prong must be thick enough to print and to bend")
assert(ring_wall >= 3, "the ring has to carry the whole towel load in tension")
assert(
  rod_reach - ring_radius > band,
  "the ring has to hang clear of the leg, or a towel would sit on the panel"
)
assert(
  arm_bottom < -rod_drop and arm_top > -rod_drop,
  "the arm has to meet the ring across its middle, not graze its edge"
)
assert(
  relief_depth < band,
  "the relief must not cut through the leg's back face"
)
assert(
  prong_back > relief_depth,
  "the prongs have to sit behind the radiator's rolled top edge"
)
assert(
  2 * notch_fillet < relief_depth
    and notch_fillet + roof_fillet < relief_height,
  "the notch's roundings have to leave a flat ledge and a flat wall between"
)
-- Nothing stands in the notch between the roof's fillet and the prongs, so
-- the slot is cut off halfway along it: any further forward and it would take
-- the fillet with it, in the middle of the part only
assert(
  relief_depth + roof_fillet < prong_back,
  "the roof's fillet has to finish before the prongs start"
)
local slot_front = -(relief_depth + roof_fillet + prong_back) / 2
assert(
  prong_tip[2] - prong_tip_radius > foot_y - foot_radius,
  "the prongs must stay shorter than the leg, so the bracket goes on leg first"
)
assert(
  cap_center[1] - cap_radius < prong_tip[1] - prong_tip_radius,
  "the nose cap is the backmost feature, so nothing snags going in"
)

-- Lua only has a one-argument arctangent, so the quadrant is put back by hand
local function bearing(dx, dy)
  if dx > 0 then
    return math.atan(dy / dx)
  end
  if dx < 0 then
    return math.atan(dy / dx) + (dy < 0 and -math.pi or math.pi)
  end
  return dy < 0 and -math.pi / 2 or math.pi / 2
end

-- Intersection of two circles; side (1 or -1) picks one of the two points
local function circle_intersection(c1, r1, c2, r2, side)
  local dx, dy = c2[1] - c1[1], c2[2] - c1[2]
  local distance = math.sqrt(dx * dx + dy * dy)
  assert(
    distance < r1 + r2 and distance > math.abs(r1 - r2),
    "fillet radius leaves nothing to be tangent to"
  )
  local along = (distance * distance + r1 * r1 - r2 * r2) / (2 * distance)
  local across = math.sqrt(r1 * r1 - along * along)
  return {
    c1[1] + (along * dx + side * across * dy) / distance,
    c1[2] + (along * dy - side * across * dx) / distance,
  }
end

-- Centre of a fillet of radius r rolling along a horizontal face at height y
-- and around a circle. `above` puts the fillet on top of the face, `ahead`
-- puts it on the +x side of the circle.
local function fillet_line_circle(y, above, center, radius, r, ahead)
  local cy = y + (above and r or -r)
  local reach = radius + r
  local rise = cy - center[2]
  local run = math.sqrt(reach * reach - rise * rise)
  return { center[1] + (ahead and run or -run), cy }
end

-- The point of a circle that lies on the ray from its centre towards `point`,
-- which is where a fillet centred there touches it
local function on_circle(center, radius, point)
  local dx, dy = point[1] - center[1], point[2] - center[2]
  local length = math.sqrt(dx * dx + dy * dy)
  return { center[1] + radius * dx / length, center[2] + radius * dy / length }
end

-- Unit direction, pointing downwards, of the line through `from` that is
-- tangent to a circle and passes in front of it
local function tangent_direction(from, center, radius)
  local vx, vy = center[1] - from[1], center[2] - from[2]
  local length = math.sqrt(vx * vx + vy * vy)
  local sin_a = radius / length
  local cos_a = math.sqrt(1 - sin_a * sin_a)
  local best
  for _, turn in ipairs({ 1, -1 }) do
    local dx = (vx * cos_a - turn * vy * sin_a) / length
    local dy = (vx * turn * sin_a + vy * cos_a) / length
    -- Where this line crosses the circle centre's height
    local x = from[1] + dx * (vy / dy)
    if not best or x > best.x then
      best = { x = x, dx = dx, dy = dy }
    end
  end
  return best.dx, best.dy
end

-- The top edge runs flat over the nose, rolls down over the shoulder, and
-- meets the arm's flat top through a fillet tangent to both
local nose_arm_fillet_center = fillet_line_circle(
  arm_top, true, shoulder_center, shoulder_radius, nose_arm_fillet, true
)
local arm_ring_fillet_center = fillet_line_circle(
  arm_top, true, rod_center, ring_radius, arm_ring_fillet, false
)
assert(
  nose_arm_fillet_center[1] < arm_ring_fillet_center[1],
  "the two fillets off the arm's top face must leave a flat section between"
)

-- The window's corners: three fillets against the ring and the strut, plus the
-- big one where the arm turns down into the leg
local window_arm_leg_fillet_center =
  { band + window_arm_leg_fillet, arm_bottom - window_arm_leg_fillet }
local window_arm_ring_fillet_center = fillet_line_circle(
  arm_bottom, false, rod_center, ring_radius, window_arm_ring_fillet, false
)
local window_strut_ring_fillet_center = circle_intersection(
  rod_center,
  ring_radius + window_strut_ring_fillet,
  strut_center,
  strut_window_radius + window_strut_ring_fillet,
  1
)
local window_strut_leg_fillet_center = {
  band + window_strut_leg_fillet,
  strut_center[2] + math.sqrt(
    (strut_window_radius + window_strut_leg_fillet) ^ 2
      - (band + window_strut_leg_fillet - strut_center[1]) ^ 2
  ),
}
local strut_ring_fillet_center = circle_intersection(
  rod_center,
  ring_radius + strut_ring_fillet,
  strut_center,
  strut_outer_radius - strut_ring_fillet,
  1
)
assert(
  window_arm_leg_fillet_center[1] < window_arm_ring_fillet_center[1],
  "the window needs a flat top edge between its two upper corners"
)

--------------------------------------------------------------------------------
-- Outline
--------------------------------------------------------------------------------

-- Both the outer edge and the window are walked once round as a chain of arcs
-- and straight faces, each leaving off exactly where the next takes over. That
-- is the whole reason they are built this way: a fillet added as its own patch
-- has to land on a tangency, and no boolean can do that cleanly - it either
-- steps off the face it meets or smears into it for half a millimetre.

local function disc(center, radius, segments)
  return circle({ r = radius, segments = segments })
    :translate(center[1], center[2], 0)
end

-- Points along a circle from one of its points to another. `direction` forces
-- the sweep to run one way round, 1 anticlockwise and -1 clockwise; left out,
-- the short way is taken. Resolution is capped in chord length and in angle
-- both, so small fillets come out as smooth as long sweeps.
local function arc_points(center, radius, from_point, to_point, direction)
  local from_angle =
    bearing(from_point[1] - center[1], from_point[2] - center[2])
  local to_angle = bearing(to_point[1] - center[1], to_point[2] - center[2])
  if direction == nil then
    while to_angle - from_angle > math.pi do
      to_angle = to_angle - 2 * math.pi
    end
    while from_angle - to_angle > math.pi do
      to_angle = to_angle + 2 * math.pi
    end
  elseif direction > 0 then
    while to_angle <= from_angle do
      to_angle = to_angle + 2 * math.pi
    end
  else
    while to_angle >= from_angle do
      to_angle = to_angle - 2 * math.pi
    end
  end
  local sweep = math.abs(to_angle - from_angle)
  local steps = math.max(
    math.ceil(sweep * radius / arc_chord),
    math.ceil(sweep / math.rad(arc_step)),
    1
  )
  local points = {}
  for step = 0, steps do
    local at = from_angle + (to_angle - from_angle) * step / steps
    points[#points + 1] =
      { center[1] + radius * math.cos(at), center[2] + radius * math.sin(at) }
  end
  return points
end

-- Outward normal of a line running tangent to two circles; `towards` picks
-- which of the two such lines by pointing roughly the way its normal should
local function common_tangent_normal(c1, r1, c2, r2, towards)
  local vx, vy = c1[1] - c2[1], c1[2] - c2[2]
  local length = math.sqrt(vx * vx + vy * vy)
  local cos_a = (r2 - r1) / length
  local sin_a = math.sqrt(math.max(0, 1 - cos_a * cos_a))
  local ux, uy = vx / length, vy / length
  local best
  for _, turn in ipairs({ 1, -1 }) do
    local normal =
      { cos_a * ux - turn * sin_a * uy, cos_a * uy + turn * sin_a * ux }
    local score = normal[1] * towards[1] + normal[2] * towards[2]
    if not best or score > best.score then
      best = { score = score, normal = normal }
    end
  end
  return best.normal
end

-- Where a circle touches a line given by its outward normal
local function touch_along(center, radius, normal)
  return { center[1] + radius * normal[1], center[2] + radius * normal[2] }
end

-- Where a circle touches a line given by a point on it and its direction
local function touch_from(center, from, dx, dy)
  local along = (center[1] - from[1]) * dx + (center[2] - from[2]) * dy
  return { from[1] + along * dx, from[2] + along * dy }
end

-- Join runs of points into one closed loop, dropping the point each run
-- shares with the one before it, and the one the walk closes on
local function closed_loop(runs)
  local points = {}
  for _, run in ipairs(runs) do
    for i, point in ipairs(run) do
      if #points == 0 or i > 1 then
        points[#points + 1] = point
      end
    end
  end
  points[#points] = nil
  local twice_area = 0
  for i = 1, #points do
    local p, q = points[i], points[i % #points + 1]
    twice_area = twice_area + p[1] * q[2] - q[1] * p[2]
  end
  if twice_area < 0 then
    local reversed = {}
    for i = #points, 1, -1 do
      reversed[#reversed + 1] = points[i]
    end
    points = reversed
  end
  return polygon({ points = points })
end

-- The bracket's outer edge, walked from the back of the nose over the top,
-- out to the ring, back along the strut to the foot, up the radiator's front
-- face and out along the prongs
local function hanger_outline()
  -- The nose's flat top is the common tangent of its two circles, and the
  -- prongs' back face is the cap's common tangent with the prong tip
  local up = common_tangent_normal(
    cap_center, cap_radius, shoulder_center, shoulder_radius, { 0, 1 }
  )
  local back = common_tangent_normal(
    cap_center, cap_radius, prong_tip, prong_tip_radius, { -1, 0 }
  )
  local cap_top = touch_along(cap_center, cap_radius, up)
  local shoulder_top = touch_along(shoulder_center, shoulder_radius, up)
  local cap_back = touch_along(cap_center, cap_radius, back)
  local tip_back = touch_along(prong_tip, prong_tip_radius, back)

  local roof_back = { -prong_back, 0 }
  local face_dx, face_dy =
    tangent_direction(roof_back, prong_tip, prong_tip_radius)
  local tip_front = touch_from(prong_tip, roof_back, face_dx, face_dy)

  local shoulder_blend =
    on_circle(shoulder_center, shoulder_radius, nose_arm_fillet_center)
  local arm_back = { nose_arm_fillet_center[1], arm_top }
  local arm_front = { arm_ring_fillet_center[1], arm_top }
  local ring_top = on_circle(rod_center, ring_radius, arm_ring_fillet_center)
  local ring_bottom =
    on_circle(rod_center, ring_radius, strut_ring_fillet_center)
  local strut_blend =
    on_circle(strut_center, strut_outer_radius, strut_ring_fillet_center)
  local strut_foot = circle_intersection(
    strut_center, strut_outer_radius, foot_center, foot_radius, -1
  )
  local roof_front = { -relief_depth - roof_fillet, 0 }
  local roof_center = { -relief_depth - roof_fillet, -roof_fillet }

  -- The ledge's two corners, and the one where the roof turns down onto the
  -- prongs. That last face is not vertical, so its fillet is found by walking
  -- one radius off the face and dropping to one radius under the roof.
  local ledge_low = -relief_height - notch_fillet
  local leg_ledge_center = { -notch_fillet, ledge_low }
  local ledge_end = -relief_depth + notch_fillet
  local wall_low = -relief_height + notch_fillet
  local ledge_wall_center = { ledge_end, wall_low }

  local off_face = { -face_dy * notch_fillet, face_dx * notch_fillet }
  local along = (-notch_fillet - off_face[2]) / face_dy
  local roof_prong_center = {
    roof_back[1] + off_face[1] + along * face_dx,
    roof_back[2] + off_face[2] + along * face_dy,
  }
  local roof_prong_roof = { roof_prong_center[1], 0 }
  local roof_prong_face = {
    roof_prong_center[1] - off_face[1],
    roof_prong_center[2] - off_face[2],
  }

  return closed_loop({
    arc_points(cap_center, cap_radius, cap_back, cap_top),
    { cap_top, shoulder_top }, -- The nose's flat top
    arc_points(shoulder_center, shoulder_radius, shoulder_top, shoulder_blend),
    arc_points(
      nose_arm_fillet_center, nose_arm_fillet, shoulder_blend, arm_back
    ),
    { arm_back, arm_front }, -- The arm's flat top
    arc_points(arm_ring_fillet_center, arm_ring_fillet, arm_front, ring_top),
    -- The long way round the ring, out past the rod and back underneath
    arc_points(rod_center, ring_radius, ring_top, ring_bottom, -1),
    arc_points(
      strut_ring_fillet_center, strut_ring_fillet, ring_bottom, strut_blend
    ),
    arc_points(strut_center, strut_outer_radius, strut_blend, strut_foot),
    arc_points(foot_center, foot_radius, strut_foot, { 0, foot_y }, -1),
    { { 0, foot_y }, { 0, ledge_low } }, -- The leg's back face
    arc_points(
      leg_ledge_center, notch_fillet,
      { 0, ledge_low }, { -notch_fillet, -relief_height }
    ),
    { { -notch_fillet, -relief_height }, { ledge_end, -relief_height } },
    arc_points(
      ledge_wall_center, notch_fillet,
      { ledge_end, -relief_height }, { -relief_depth, wall_low }
    ),
    { { -relief_depth, wall_low }, { -relief_depth, -roof_fillet } },
    arc_points(
      roof_center, roof_fillet, { -relief_depth, -roof_fillet }, roof_front
    ),
    { roof_front, roof_prong_roof }, -- The roof, resting on the grill
    arc_points(
      roof_prong_center, notch_fillet, roof_prong_roof, roof_prong_face
    ),
    { roof_prong_face, tip_front }, -- The prongs' front face
    arc_points(prong_tip, prong_tip_radius, tip_front, tip_back, -1),
    { tip_back, cap_back }, -- The prongs' back face
  })
end

-- The triangular window between arm, leg, strut and ring, walked the same way
local function window_outline()
  local top_left = { window_arm_leg_fillet_center[1], arm_bottom }
  local top_right = { window_arm_ring_fillet_center[1], arm_bottom }
  local ring_top =
    on_circle(rod_center, ring_radius, window_arm_ring_fillet_center)
  local ring_bottom =
    on_circle(rod_center, ring_radius, window_strut_ring_fillet_center)
  local strut_top = on_circle(
    strut_center, strut_window_radius, window_strut_ring_fillet_center
  )
  local strut_foot = on_circle(
    strut_center, strut_window_radius, window_strut_leg_fillet_center
  )
  local leg_bottom = { band, window_strut_leg_fillet_center[2] }
  local leg_top = { band, window_arm_leg_fillet_center[2] }

  return closed_loop({
    { top_left, top_right }, -- The arm's underside
    arc_points(
      window_arm_ring_fillet_center, window_arm_ring_fillet,
      top_right, ring_top
    ),
    arc_points(rod_center, ring_radius, ring_top, ring_bottom),
    arc_points(
      window_strut_ring_fillet_center, window_strut_ring_fillet,
      ring_bottom, strut_top
    ),
    arc_points(strut_center, strut_window_radius, strut_top, strut_foot),
    arc_points(
      window_strut_leg_fillet_center, window_strut_leg_fillet,
      strut_foot, leg_bottom
    ),
    { leg_bottom, leg_top }, -- The leg's front face
    arc_points(
      window_arm_leg_fillet_center, window_arm_leg_fillet, leg_top, top_left
    ),
  })
end

-- The slot the grill bar runs up, between the prongs and as far as the roof.
-- It only ever meets the prongs, so it can be left square.
local function prong_slot()
  local far = 400
  return rect({ far, far }):translate(slot_front - far, -far, 0)
end

--------------------------------------------------------------------------------
-- Solid
--------------------------------------------------------------------------------

-- Both flat faces get the same 45 degree edge break the original has: a
-- Minkowski sum of the outline, inset by the chamfer and extruded that much
-- shorter, with a double cone, so the sum lands back on the outline at mid
-- height and slopes away from it at both ends. Both cones are truncated
-- rather than run to a point: a degenerate apex leaves stray shells behind.
--
-- The slot is cut afterwards and so keeps square edges, on purpose. Printed
-- flat, its far wall is bridged across the gap, and a bridge starts better
-- off a square edge than off a slope.
local function hanger()
  local bevel = cylinder({
    r1 = edge_chamfer, r2 = chamfer_tip, h = edge_chamfer,
    segments = chamfer_segments,
  }) + cylinder({
    r1 = chamfer_tip, r2 = edge_chamfer, h = edge_chamfer,
    segments = chamfer_segments,
  }):translate(0, 0, -edge_chamfer)
  local solid = (
    hanger_outline()
    - window_outline()
    - disc(rod_center, rod_hole_radius, hole_segments)
  )
    :offset(-edge_chamfer)
    :linear_extrude({ h = part_width - 2 * edge_chamfer, center = true })
    :minkowski(bevel)

  -- Split the prongs: the grill bar runs up this slot until it meets the roof
  local slot = prong_slot():linear_extrude({ h = prong_gap, center = true })
  return solid - slot
end

-- Printed lying on its side, which is how the profile was drawn
render(
  hanger()
    :translate(0, 0, part_width / 2)
    :color("white")
    :material("plastic", { roughness = 0.35 })
    :name("radiator_towel_hanger")
)
