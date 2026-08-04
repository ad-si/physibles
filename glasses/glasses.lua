-- All measures in mm

-- Set to true to lay the parts out flat on the build plate for FDM printing
local print_view = true


--// Frame
local frame_half_width = 70.5
local frame_depth = 17.766666

local bridge_width = 17
local frame_height = 40


--// Lens
local _glass_thickness = 3
local glass_width = 54.2
local glass_height = 34
-- Calculated in radius_glass_calculation.slvs
local glass_radius = 91.6


--// Hinge pockets
-- The temples are glued into them during assembly
local hinge_pocket_width = 5 -- Matches tracings/hinge_cutout.svg
local hinge_pocket_height = 3.2 -- Matches tracings/hinge_cutout.svg
-- Pocket depth is just a guess,
-- because it can't be measured as it is hidden
local hinge_pocket_depth = 3

-- Position in the coordinate system of `frame_front_half`.
-- Sits as far out as the wall towards the frame's outer edge allows,
-- so that the temples can run flush with it.
local hinge_pocket_x = frame_half_width - 6.5
local hinge_pocket_y = frame_height - 9
local hinge_pocket_z = hinge_pocket_depth - 10.4

-- Center of the same pocket in the coordinate system of the assembled glasses
local pocket_center_x = hinge_pocket_x + hinge_pocket_width / 2
local pocket_center_y = hinge_pocket_y + hinge_pocket_height / 2
  - frame_height / 2
local pocket_center_z = hinge_pocket_z + frame_depth / 2
-- Where the pocket opens towards the back of the glasses
local pocket_mouth_z = pocket_center_z - hinge_pocket_depth / 2


local function stacked_cylinder(ridge_height, ridge_thickness)
  ridge_height = ridge_height or 1
  ridge_thickness = ridge_thickness or 2
  return cylinder { h = ridge_thickness / 2, r1 = ridge_height, r2 = 0 }
    + cylinder { h = ridge_thickness / 2, r1 = 0, r2 = ridge_height }
        :translate(0, 0, -(ridge_thickness / 2))
end


local function sphere_slice(thickness)
  local resolution = 50 -- 15 - 200
  local sp_radius = glass_radius
  return sphere { r = sp_radius, fn = resolution }
      :translate(0, 0, -sp_radius)
    - sphere { r = sp_radius, fn = resolution }
        :translate(0, 0, -sp_radius - thickness)
end


local function glass_slice(thickness)
  return import("tracings/lens_outline.svg")
      :translate(-glass_width / 2, -glass_height / 2)
      :linear_extrude(1000, { center = true })
    * sphere_slice(thickness)
end


local function glass()
  local brim_depth = 20
  local slice_thickness = 2
  local empirical_offset = 12.65

  -- FIXME: This is technically not correct,
  -- since a vertically moved `stacked_cylinder`
  -- creates a round ridge, and not a sharp ridge.
  -- I couldn't come up with a better way to implement this,
  -- but since the lens is pretty flat, it's good enough.
  -- Also seems to cause non-manifold edges sometimes,
  -- but not bad enough to cause problems in slicers.
  return glass_slice(0.0001)
      :minkowski(stacked_cylinder(1, slice_thickness))
      :translate(0, 0, slice_thickness / 2 + empirical_offset)
    + glass_slice(brim_depth)
        :translate(0, 0, (brim_depth / 2) + empirical_offset)
end


-- `oversize` grows the pocket in all directions.
-- Trimming the temples with an oversized copy avoids coincident walls,
-- which would leave slivers of the temple standing in the pocket.
local function hinge_pocket(oversize)
  oversize = oversize or 0
  local outline = import("tracings/hinge_cutout.svg")

  if oversize > 0 then
    outline = outline:offset(oversize)
  end

  return outline
    :linear_extrude(hinge_pocket_depth + 2 * oversize, { center = true })
end


local function frame_front_half()
  return import("tracings/frame_front.svg")
      :linear_extrude(frame_depth * 1.5, { center = true })
    - hinge_pocket()
        :translate(hinge_pocket_x, hinge_pocket_y, hinge_pocket_z)
end


local function frame_top_half()
  return import("tracings/frame_top.svg")
    :linear_extrude(frame_height * 1.5, { center = true })
end


local function frame()
  -- This is necessary to avoid non manifold edges
  local overlap = 0.001

  local front_halves = (
      frame_front_half():translate(-overlap, 0, 0)
      + frame_front_half():translate(-overlap, 0, 0):mirror(1, 0, 0)
    ):translate(0, -frame_height / 2, 0)

  local top_halves = (
      frame_top_half():translate(-overlap, 0, 0)
      + frame_top_half():translate(-overlap, 0, 0):mirror(1, 0, 0)
    )
      :translate(0, -frame_depth / 2, 0)
      :rotate(270, 0, 0)

  return front_halves * top_halves
end


local function lens_positioned()
  -- Following values were determined by visually checking
  -- that the lens is in the center of the frame
  local empirical_offset = -2

  local empirical_pitch = 9.5
  local empirical_roll = -1
  local empirical_yaw = 0

  return glass()
    :rotate(empirical_yaw, empirical_pitch, empirical_roll)
    :translate(glass_width / 2 + bridge_width / 2 + empirical_offset, 0, 0)
end


local frame_positioned = frame():translate(0, 0, frame_depth / 2)


--// Temples
-- Reaching ~140 mm behind the front of the frame,
-- splaying outwards and bending down behind the ear
local temple_reach = 140 -- From the front of the frame to the tip
local temple_shaft_splay = 2 -- How far the shaft drifts outwards
-- Outer face of the temples, flush with the outer edge of the frame
local temple_outer_x = frame_half_width - 0.4
-- Top face of the temples, flush with the top edge of the frame's end
local temple_top_y = 16
local temple_bend_radius = 25
local temple_bend_angle = 40
local temple_bend_hook = 3 -- How far the bend drifts inwards
local temple_tip_length = 32 -- Straight part behind the bend
-- Rounded off end of the tip: distance from the end, width and height
local temple_tip_rounding = {
  { 4.0, 3.0, 6.0 },
  { 2.4, 2.8, 5.2 },
  { 1.0, 2.4, 3.8 },
  { 0.0, 2.0, 2.0 },
}
local temple_corner_radius = 1 -- Rounding of the rectangular profile
local temple_fit_clearance = 0.15 -- Gap for the glue in the hinge pocket

local temple_bend_length = temple_bend_radius * math.rad(temple_bend_angle)
-- Straight part from the frame to the bend, filling up the reach
local temple_shaft_length = temple_reach
  - (frame_depth - pocket_mouth_z)
  - temple_bend_radius * math.sin(math.rad(temple_bend_angle))
  - temple_tip_length * math.cos(math.rad(temple_bend_angle))
local temple_length = temple_shaft_length
  + temple_bend_length
  + temple_tip_length
local temple_yaw =
  -math.deg(math.atan(temple_shaft_splay / temple_shaft_length))

-- Width (x) and height (y) of the temple at a fraction of its length.
-- The first section covers the hinge pocket, behind it the width
-- stays below 3 mm to not press against the head.
-- As the outer face is flush with the frame, the taper is on the inside only.
-- It is at its lowest around the bend and gets taller again towards the tip.
local temple_sections = {
  { 0.00, 6.2, 6.0 },
  { 0.09, 3.0, 6.0 },
  { temple_shaft_length / temple_length, 2.8, 4.4 },
  { (temple_shaft_length + temple_bend_length) / temple_length, 2.8, 3.8 },
}

for _, rounding in ipairs(temple_tip_rounding) do
  temple_sections[#temple_sections + 1] = {
    (temple_length - rounding[1]) / temple_length,
    rounding[2],
    rounding[3],
  }
end


local function temple_section(fraction)
  for index = 1, #temple_sections - 1 do
    local from = temple_sections[index]
    local to = temple_sections[index + 1]
    if fraction <= to[1] then
      local ratio = (fraction - from[1]) / (to[1] - from[1])
      return from[2] + (to[2] - from[2]) * ratio,
        from[3] + (to[3] - from[3]) * ratio
    end
  end
  local last = temple_sections[#temple_sections]
  return last[2], last[3]
end


-- The temple only tapers downwards, so its top face stays flush
local function temple_center_y(fraction)
  local _, height = temple_section(fraction)
  return temple_top_y - height / 2
end


-- Corner radius and the distance of the corners from the center
local function temple_corners(fraction)
  local width, height = temple_section(fraction)
  local radius = math.min(temple_corner_radius, math.min(width, height) / 2)
  return radius, width / 2 - radius, height / 2 - radius
end


local function rounded_by(corner, offset_x, offset_y)
  return corner:translate(-offset_x, -offset_y, 0)
    + corner:translate(offset_x, -offset_y, 0)
    + corner:translate(offset_x, offset_y, 0)
    + corner:translate(-offset_x, offset_y, 0)
end


-- Cross section of the temple, as a flat cluster of spheres.
-- Hulling two of them yields a segment with rounded edges.
-- `outer_x` is the outer face, as the temple only tapers towards the face.
local function temple_slice(fraction, pitch, outer_x, y, z)
  local width = temple_section(fraction)
  local radius, offset_x, offset_y = temple_corners(fraction)

  return rounded_by(sphere { r = radius, fn = 24 }, offset_x, offset_y)
    :rotate(pitch, temple_yaw, 0)
    :translate(outer_x - width / 2, y, z)
end


-- Where the cross section sits at a given distance from the hinge pocket
local function temple_station(distance)
  local fraction = distance / temple_length

  if distance <= temple_shaft_length then
    return fraction,
      0,
      temple_outer_x + temple_shaft_splay * (distance / temple_shaft_length),
      temple_center_y(fraction),
      pocket_mouth_z - distance
  end

  -- Bend behind the ear, followed by the straight tip
  local along_bend =
    math.min(distance - temple_shaft_length, temple_bend_length)
  local along_tip =
    math.max(distance - temple_shaft_length - temple_bend_length, 0)
  local angle = math.deg(along_bend / temple_bend_radius)

  local drop = temple_bend_radius * (1 - math.cos(math.rad(angle)))
    + along_tip * math.sin(math.rad(angle))
  -- Drifting inwards with the drop keeps the hook free of kinks
  local full_drop = temple_bend_radius
      * (1 - math.cos(math.rad(temple_bend_angle)))
    + temple_tip_length * math.sin(math.rad(temple_bend_angle))

  return fraction,
    -angle,
    temple_outer_x + temple_shaft_splay - temple_bend_hook * (drop / full_drop),
    temple_center_y(temple_shaft_length / temple_length) - drop,
    pocket_mouth_z - temple_shaft_length
      - temple_bend_radius * math.sin(math.rad(angle))
      - along_tip * math.cos(math.rad(angle))
end


-- Straight piece which reaches into the frame,
-- so that the temple's front face can be trimmed flush against the frame
local function temple_root(depth)
  local width = temple_section(0)
  local radius, offset_x, offset_y = temple_corners(0)

  return rounded_by(cylinder { h = depth, r = radius, fn = 24 },
      offset_x, offset_y)
    :hull()
    :translate(temple_outer_x - width / 2, temple_center_y(0), pocket_mouth_z)
end


-- Plug which is glued into the hinge pocket
local function temple_tenon()
  local glue_gap = 0.3 -- Keeps the tenon from bottoming out in the pocket
  -- Sticks out of the pocket to merge with the temple.
  -- Must stay short, as the temple tapers away from the tenon behind the frame.
  local overlap = 0.5

  return import("tracings/hinge_cutout.svg")
    :offset(-temple_fit_clearance)
    :linear_extrude(hinge_pocket_depth - glue_gap + overlap)
    :translate(
      pocket_center_x - hinge_pocket_width / 2,
      pocket_center_y - hinge_pocket_height / 2,
      pocket_mouth_z - overlap
    )
end


local function temple()
  -- Distances along the temple at which its cross section is sampled.
  -- Closely spaced at the front, where the temple tapers quickly.
  local distances = { 0, 6, 14 }
  local shaft_steps = 4
  for step = 1, shaft_steps do
    distances[#distances + 1] =
      14 + (temple_shaft_length - 14) * (step / shaft_steps)
  end

  local bend_steps = 6
  for step = 1, bend_steps do
    distances[#distances + 1] = temple_shaft_length
      + temple_bend_length * (step / bend_steps)
  end

  distances[#distances + 1] = temple_length - temple_tip_length / 2
  for _, rounding in ipairs(temple_tip_rounding) do
    distances[#distances + 1] = temple_length - rounding[1]
  end

  local shaft = temple_root(hinge_pocket_depth)
  for index = 1, #distances - 1 do
    shaft = shaft
      + (
        temple_slice(temple_station(distances[index]))
        + temple_slice(temple_station(distances[index + 1]))
      ):hull()
  end

  local pocket_positioned = hinge_pocket(0.05):translate(
    pocket_center_x - hinge_pocket_width / 2,
    pocket_center_y - hinge_pocket_height / 2,
    pocket_center_z
  )

  return (shaft - frame_positioned - pocket_positioned) + temple_tenon()
end


local temple_right = temple()

local frame_with_lenses =
  frame_positioned
  - lens_positioned()
  - lens_positioned():mirror(1, 0, 0)


local function assembled()
  return frame_with_lenses
    + temple_right
    + temple_right:mirror(1, 0, 0)
end


--// Print view
-- All parts laid out flat on the build plate, ready to be sliced.
-- The frame keeps its orientation (front side up) and needs supports,
-- as it is curved. The temples rest on their outer faces.
local function print_layout()
  -- Packed tightly, so the print head doesn't have to travel far.
  -- The temples are ~30 mm high, the frame reaches down to -20 mm.
  local first_row = -40
  local row_pitch = 34

  -- Compensating the splay tilts the outer face flat onto the plate
  local flat_temple = temple_right
    :translate(-temple_outer_x, 0, 0)
    :rotate(0, 90 - temple_yaw, 0)
    :translate(temple_length / 2, 0, 0.01)

  return frame_with_lenses
    + flat_temple:translate(0, first_row, 0)
    + flat_temple:mirror(1, 0, 0):translate(0, first_row - row_pitch, 0)
end


if print_view then
  render(print_layout())
else
  render(assembled())
end