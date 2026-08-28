-- iPhone mount for a Samsung TV stand bar
--
-- Replaces one of the stand's two bar connectors (Samsung BN61-12322A,
-- "STAND BAR OUT"): a flat tongue with hooked edges slides into the
-- slot in the stand bar. A block joins the tongue to an arm that bends
-- 60 degrees and continues as a straight strap. The strap's front face
-- carries a round dish sized for a MagSafe puck, with a hole through
-- the strap behind it, and the flat back of the elbow has an obround
-- slot for the cable. Behind the dish the front face is dropped so
-- the phone's camera bump clears the strap. The strap tip is rounded
-- across its width.
--
-- For 3d printing the mount is cut in two at the elbow, along the
-- miter plane through both sharp corners: the "arm" (strap and dish)
-- and the "connector" (tongue, base, and elbow wedge). Two dovetail
-- keys on the arm's cut face run up the face's slope, mirrored about
-- the middle; they slide into matching sockets in the connector from
-- the elbow's outer side and stop at the sockets' closed lower ends,
-- which stay buried below the front-side surface.
--
-- Recreated from the FreeCAD model (model.FCStd) in this directory.
-- The tongue outline and its cross profile are traced from the OEM
-- connector, hence the odd coordinates.
--
-- All measures in mm

-- "assembled": as mounted on the TV: the FreeCAD model's coordinates,
--   turned so the tongue points up; both parts joined
-- "print": each part in its print orientation: the arm on the strap's
--   back (the side the through hole opens to) with the dish facing up
--   and the dovetail keys climbing the cut face; the connector on the
--   elbow's broad back with the tongue's hooks facing up; the tongue's
--   underside rests on the bed (only the wings overhang)
local view = "print" -- "assembled" or "print"
local part = "both" -- "arm", "connector", or "both"

--// Tongue (the part inside the stand bar's slot)
local tongue_width = 22 -- x
local tongue_thickness = 12 -- z
-- The hooks' barbs protrude this much past the traced OEM shape, for
-- a tighter fit in the bar's slot
local hook_grow = 0.3

--// Base block joining tongue and arm
local base_depth = 10 -- x
local base_width = 70 -- y, also the arm's width
local base_height = 14 -- z, also the arm strap's thickness

--// Arm: a sharp 60 degree elbow off the base's back, then a straight
--// strap, in the XZ plane, extruded over the full base width
local arm_sweep = 60 -- Degrees of bend at the elbow
-- Of the FreeCAD model's bend, whose fillets are removed here; kept to
-- place the strap (and thus the tip) where that model had it
local arm_inner_radius = 21.5
local arm_thickness = base_height
-- From the end of the FreeCAD model's bend to the tip. The original
-- sketch left this unconstrained; 80.152 is measured from it, plus 32
-- more between the elbow and the dish.
local strap_length = 80.152 + 32
local tip_fillet_radius = 34.99 -- Rounds the tip across the width

--// Dish for the MagSafe puck, sunk into the strap's front face
local dish_radius = 30
local dish_depth = 10
local dish_tip_offset = 35 -- Dish center up from the tip, along the face
local hole_radius = 20 -- Through hole behind the dish, same center
-- Behind the dish the front face is dropped this much, clearing the
-- phone's camera bump; a flat land runs `face_drop_land` past the
-- dish's edge before the stepdown ramps off at `face_drop_angle`, so
-- the full-height rim rings the whole dish with a margin
local face_drop = 3
local face_drop_angle = 30 -- Degrees the stepdown ramp leans off the face
-- Flat between the dish's edge and the ramp, as wide as the
-- full-height rim the rounded tip leaves around the dish
local face_drop_land = tip_fillet_radius - dish_radius

--// Cable channel: an obround cut parallel to the strap, starting
--// inside the through hole and running up inside the strap, emerging
--// through the elbow's flat back. The cable enters it via the hole.
local slot_length = 14 -- Along y
local slot_width = 8
local slot_face_depth = 1.5 -- Slot's near side below the dropped front face

--// Dovetails joining the arm to the connector: two keys on the arm's
--// cut face, running along the face's slope, mirrored about the middle
local dovetail_depth = 4 -- Key height above the cut face, along its normal
local dovetail_neck = 9 -- Key width at the cut face
local dovetail_flare = 12 -- Degrees each flank leans outward
local dovetail_spacing = 35 -- Center distance between the two keys
-- Fraction of the thickness the keys span, measured from the elbow's
-- back. The keys' lower ends must stay far enough up the cut face
-- that the sockets' closed ends stay buried below the front-side
-- surface -- shaved down to the tongue's underside -- where the
-- elbow's wedge runs out.
local dovetail_span = 2 / 3
local dovetail_clearance = 0.15 -- Socket is grown this much per side

local eps = 0.01 -- Used to prevent z-fighting

-- Lua 5.3 folded math.atan2 into math.atan; support both
local atan2 = math.atan2 or math.atan

--------------------------------------------------------------------------------

local back_x = -(tongue_width / 2 + base_depth) -- Base's back face

-- Append a point, skipping consecutive duplicates
local function add(pts, x, y)
  local last = pts[#pts]
  if last and math.abs(last[1] - x) < 1e-6 and math.abs(last[2] - y) < 1e-6 then
    return
  end
  pts[#pts + 1] = { x, y }
end

-- Append an arc around (cx, cy) from angle a0 to a1 (degrees, signed
-- direction), tessellated to a 0.005 mm sagitta
local function arc_to(pts, cx, cy, r, a0, a1)
  local step = math.deg(2 * math.acos(1 - math.min(1, 0.005 / r)))
  local steps = math.max(1, math.ceil(math.abs(a1 - a0) / step))
  for i = 0, steps do
    local a = math.rad(a0 + (a1 - a0) * i / steps)
    add(pts, cx + r * math.cos(a), cy + r * math.sin(a))
  end
end

-- Drop a closing point that duplicates the first
local function close_outline(pts)
  local first, last = pts[1], pts[#pts]
  if math.abs(first[1] - last[1]) < 1e-6
    and math.abs(first[2] - last[2]) < 1e-6 then
    pts[#pts] = nil
  end
  return pts
end


-- Outline of the tongue in the XY plane, traced from the OEM part.
-- One half (y < 0) is listed; the other is mirrored. Walking from the
-- back edge: the long straight flank, a small step, then the ramped
-- hook (120 degree corners) whose barb dips into the deepest point
-- before rising to the front corner.
local function tongue_outline()
  -- The hook's arcs: the shoulder (a) where the ramp leaves the recess,
  -- the barb tip (b), and the front corner (c). The barb center is
  -- pushed out by `hook_grow`, and the tangent lines joining the arcs
  -- are recomputed so the ramps stay tangent to it.
  local ax, ay, ar = 6.2043, -24.2019, 0.3
  local bx, by, br = 8.0194, -25.7458 - hook_grow, 0.5
  local cx, cy, cr = 10.5, -23.7598, 0.5
  -- Down ramp, tangent inside a and b: touches a at `down`, b opposite
  local dx, dy = bx - ax, by - ay
  local down = math.deg(
    atan2(dy, dx) + math.acos((ar + br) / math.sqrt(dx * dx + dy * dy))
  )
  -- Up ramp, tangent outside b and c (equal radii): square to b -> c
  local up = math.deg(atan2(cy - by, cx - bx)) + 270

  local pts = {}
  add(pts, -11, 0)
  add(pts, -11, -25.2481)
  add(pts, -7.25, -25.2481)
  arc_to(pts, -7.25, -24.9981, 0.25, -90, 0)
  add(pts, -7, -23.4981)
  arc_to(pts, -6.75, -23.4981, 0.25, 180, 90)
  add(pts, 3.8557, -23.2481)
  arc_to(pts, 3.8557, -23.4981, 0.25, 90, 30)
  add(pts, 4.3053, -23.7769)
  arc_to(pts, 4.5218, -23.6519, 0.25, 210, 270)
  add(pts, ax, -23.9019)
  arc_to(pts, ax, ay, ar, 90, down)
  arc_to(pts, bx, by, br, down + 180, up)
  arc_to(pts, cx, cy, cr, up, 360)
  add(pts, 11, -23.7598)
  add(pts, 11, 0)
  for i = #pts - 1, 2, -1 do
    add(pts, pts[i][1], -pts[i][2])
  end
  return close_outline(pts)
end


-- The tongue: its outline extruded upright, intersected with the
-- mating cross profile (in the YZ plane, extruded across) traced from
-- the OEM part: a 12 high rail with 7 high wings past y = +-22, and a
-- staggered channel through the middle (bottom notch and top notch on
-- the same side, leaving a central bridge). The wings nominally reach
-- y = +-28 and are clipped by the outline.
local function tongue()
  local plan = polygon { points = tongue_outline() }
    :linear_extrude(tongue_thickness + 2 * eps)
    :translate(0, 0, -eps)

  local cross = polygon { points = {
    { -22, 0 }, { 0, 0 }, { 0, 4 }, { 6, 4 }, { 6, 0 }, { 22, 0 },
    { 22, 2.5 }, { 28, 2.5 }, { 28, 9.5 }, { 22, 9.5 }, { 22, 12 },
    { 6, 12 }, { 6, 8 }, { 0, 8 }, { 0, 12 }, { -22, 12 },
    { -22, 9.5 }, { -28, 9.5 }, { -28, 2.5 }, { -22, 2.5 },
  } }
    :linear_extrude(tongue_width + 2 * eps)
    :rotate(90, 0, 90)
    :translate(-tongue_width / 2 - eps, 0, 0)

  -- The tongue is 2 thinner than the base; align it with the base's
  -- top so its underside rests on the bed in the connector's flipped
  -- print orientation
  return (plan * cross):translate(0, 0, base_height - tongue_thickness)
end


local function base()
  return cube { { base_depth, base_width, base_height } }
    :translate(back_x, -base_width / 2, 0)
end


-- Arm layout in the XZ plane. The strap lies where the FreeCAD
-- model's filleted bend put it: tangent to an `arm_inner_radius` arc
-- springing from the base's bottom back corner and sweeping
-- `arm_sweep`. The fillets themselves are gone: the base's bottom and
-- top planes run straight back and meet the strap's faces in sharp
-- corners. The tip cap runs from the strap's inner to its outer
-- corner, perpendicular to the strap.
local bend_z = -arm_inner_radius
local cap_angle = math.rad(90 + arm_sweep)
local down_angle = math.rad(180 + arm_sweep) -- Down along the strap
local tip_inner_x = back_x + arm_inner_radius * math.cos(cap_angle)
  + strap_length * math.cos(down_angle)
local tip_inner_z = bend_z + arm_inner_radius * math.sin(cap_angle)
  + strap_length * math.sin(down_angle)
local tip_outer_x = tip_inner_x + arm_thickness * math.cos(cap_angle)
local tip_outer_z = tip_inner_z + arm_thickness * math.sin(cap_angle)
local tip_mid_x = (tip_inner_x + tip_outer_x) / 2
local tip_mid_z = (tip_inner_z + tip_outer_z) / 2

-- The sharp corners sit where the tangent lines to each bend circle
-- meet: `r * tan(arm_sweep / 2)` behind the tangency point
local knee_tan = math.tan(math.rad(arm_sweep / 2))

local function arm_profile()
  return {
    { back_x, base_height },
    { back_x, 0 },
    { back_x - arm_inner_radius * knee_tan, 0 },
    { tip_inner_x, tip_inner_z },
    { tip_outer_x, tip_outer_z },
    { back_x - (arm_inner_radius + arm_thickness) * knee_tan, base_height },
  }
end

-- Place a cutter modeled in the strap's frame: origin at the center of
-- the tip cap, x towards the front face (the face is at x = half the
-- strap thickness), z up along the strap
local function strap_frame(solid)
  return solid
    :rotate(0, 90 - arm_sweep, 0)
    :translate(tip_mid_x, 0, tip_mid_z)
end

-- The cable channel, in the strap's frame: an obround prism starting
-- 50 up from the tip, safely inside the void the hole and dish leave,
-- and running out through the top of the bend
local function cable_slot()
  local slot_reach = math.max(0, slot_length - slot_width) / 2
  local slot_pin = cylinder { h = 200, r = slot_width / 2, fn = 48 }
  local slot = (
    slot_pin:translate(0, slot_reach, 0)
    + slot_pin:translate(0, -slot_reach, 0)
  ):hull()
  return slot:translate(
    arm_thickness / 2 - face_drop - slot_face_depth - slot_width / 2,
    0,
    50
  )
end

local function arm()
  local half = arm_thickness / 2

  local body = polygon { points = arm_profile() }
    :linear_extrude(base_width)
    :rotate(90, 0, 0)
    :translate(0, base_width / 2, 0)

  local dish = cylinder { h = dish_depth + eps, r = dish_radius, fn = 180 }
    :rotate(0, -90, 0)
    :translate(half + eps, 0, dish_tip_offset)

  local hole = cylinder {
    h = arm_thickness + 2 * eps,
    r = hole_radius,
    fn = 144,
  }
    :rotate(0, -90, 0)
    :translate(half + eps, 0, dish_tip_offset)

  -- Rounding the tip: at each side, cut the corner between the tip cap
  -- and the side face down to a cylinder tangent to both
  local function tip_corner(side)
    local fr = tip_fillet_radius
    local axis_y = side * (base_width / 2 - fr)
    local block = cube { { 20, fr + eps, fr + eps } }
      :translate(-10, side > 0 and axis_y or -base_width / 2 - eps, -eps)
    local roll = cylinder { h = 20 + 2 * eps, r = fr, fn = 192 }
      :rotate(0, 90, 0)
      :translate(-10 - eps, axis_y, fr)
    return block - roll
  end

  return body
    - strap_frame(dish)
    - strap_frame(hole)
    - strap_frame(cable_slot())
    - strap_frame(tip_corner(1))
    - strap_frame(tip_corner(-1))
end


-- The cut at the elbow: the miter plane through the sharp inner and
-- outer corner, bisecting the bend. Local frame: origin on the inner
-- corner, x along the plane's normal towards the tongue, z along the
-- cut face towards the outer corner, y across the width.
local miter_x = back_x - arm_inner_radius * knee_tan -- Inner corner
local miter_face = arm_thickness / math.cos(math.rad(arm_sweep / 2))

local function miter_frame(solid)
  return solid
    :rotate(0, -arm_sweep / 2, 0)
    :translate(miter_x, 0, 0)
end

-- Position along the face runs linearly from the front (inner corner)
-- to the back of the thickness, so the keys start after the fraction
-- they leave uncovered
local dovetail_lift = (1 - dovetail_span) * miter_face

-- The two dovetail key prisms, in the miter frame: the cross profile
-- in the XY plane, extruded up the cut face from `dovetail_lift` and
-- grown by `grow` on every side for the socket's clearance. The
-- extrusion overshoots the outer corner, where the sockets are open
-- for sliding the keys in; their lower ends stay closed and buried,
-- stopping the keys.
local function dovetail(grow)
  local half_neck = dovetail_neck / 2 + grow
  local depth = dovetail_depth + grow
  local half_root = half_neck + depth * math.tan(math.rad(dovetail_flare))
  local key = polygon { points = {
    { -grow - eps, -half_neck },
    { depth, -half_root },
    { depth, half_root },
    { -grow - eps, half_neck },
  } }
    :linear_extrude(miter_face - dovetail_lift + grow + 1)
    :translate(0, 0, dovetail_lift - grow)
  return key:translate(0, dovetail_spacing / 2, 0)
    + key:translate(0, -dovetail_spacing / 2, 0)
end

local whole = tongue() + base() + arm()
local tongue_side = miter_frame(
  cube { { 300, 200, 400 } }:translate(0, -100, -200)
)

-- The connector's front-side face is shaved this deep, flush with the
-- thinner tongue's underside (see `front_shave` below)
local front_shave_depth = base_height - tongue_thickness

-- Dropping the face behind the dish: a slab with a ramped leading
-- edge -- cresting at face height a land's length past the dish's
-- edge, falling at `face_drop_angle` to `face_drop` below --
-- extruded across the width and run out past the cut face,
-- subtracted from the arm part alone so the overshoot cannot nick
-- the elbow wedge
local drop_edge = dish_tip_offset + dish_radius + face_drop_land -- Ramp crest
local drop_run = face_drop / math.tan(math.rad(face_drop_angle))
local face_drop_cut = strap_frame(
  polygon { points = {
    { arm_thickness / 2 + eps, drop_edge },
    { arm_thickness / 2 + eps, 300 },
    { arm_thickness / 2 - face_drop, 300 },
    { arm_thickness / 2 - face_drop, drop_edge + drop_run },
  } }
    :linear_extrude(base_width + 2 * eps)
    :rotate(90, 0, 0)
    :translate(0, base_width / 2 + eps, 0)
)

-- The keys are clipped to the whole mount, so their ends stay flush
-- with its outer faces
local arm_part = (whole - tongue_side) - face_drop_cut
  + (miter_frame(dovetail(0)) * whole)
-- The base is thicker than the tongue, so the connector's flipped
-- print would step down where the tongue begins; shave the front-side
-- face (the print's top) flush with the tongue's underside. The slab
-- overshoots the miter plane, where the part is void anyway.
local front_shave = cube { {
  72,
  base_width + 2 * eps,
  front_shave_depth + eps,
} }
  :translate(-60, -base_width / 2 - eps, -eps)

-- The arm's face drop is deeper than the front shave, so the parts
-- would meet at different thicknesses; the base's and wedge's face
-- steps down once more -- ramped at the same angle, cresting halfway
-- across the base's underside -- so both parts share the same
-- thickness at the dovetail connection
local joint_drop = face_drop - front_shave_depth
local joint_run = joint_drop / math.tan(math.rad(face_drop_angle))
local joint_crest = back_x + base_depth / 2
local joint_shave = polygon { points = {
  { joint_crest, front_shave_depth - eps },
  { joint_crest - joint_run, front_shave_depth + joint_drop },
  { -60, front_shave_depth + joint_drop },
  { -60, front_shave_depth - eps },
} }
  :linear_extrude(base_width + 2 * eps)
  :rotate(90, 0, 0)
  :translate(0, base_width / 2 + eps, 0)

local connector_part = (whole * tongue_side)
  - miter_frame(dovetail(dovetail_clearance))
  - front_shave
  - joint_shave


local mount
if view == "print" then
  -- Arm: lay the strap's back face on the bed (the through hole opens
  -- to it), lift it to the bed, and center the footprint on the plate.
  -- `ax, az` is where the old x and z axes land on the new x axis;
  -- the strap runs along +x, the cut face trails behind -x.
  local ax = -math.cos(math.rad(arm_sweep))
  local az = -math.sin(math.rad(arm_sweep))
  local face_nx = math.cos(math.rad(arm_sweep - 90))
  local face_nz = math.sin(math.rad(arm_sweep - 90))
  local x_tip = tip_mid_x * ax + tip_mid_z * az
  local x_cut = (back_x - (arm_inner_radius + arm_thickness) * knee_tan) * ax
    + base_height * az
  local arm_print = arm_part
    :rotate(0, arm_sweep + 180, 0)
    :translate(
      -(x_tip + x_cut) / 2,
      0,
      arm_thickness / 2 - (tip_mid_x * face_nx + tip_mid_z * face_nz)
    )

  -- Connector: flip it onto the elbow's broad back face (the sockets'
  -- open ends land on the bed) and center the footprint, which runs
  -- from the outer corner to the tongue's tip
  local conn_back = (arm_inner_radius + arm_thickness) * knee_tan - back_x
  local conn_print = connector_part
    :rotate(0, 180, 0)
    :translate(
      -(conn_back - tongue_width / 2) / 2,
      part == "both" and base_width + 10 or 0,
      base_height
    )

  if part == "arm" then
    mount = arm_print
  elseif part == "connector" then
    mount = conn_print
  else
    mount = arm_print + conn_print
  end
else
  -- The parts are modeled with the tongue along +x; turn them so the
  -- tongue points up
  mount = (part == "arm" and arm_part)
    or (part == "connector" and connector_part)
    or (arm_part + connector_part)
  mount = mount:rotate(0, -90, 0)
end

render(mount)
