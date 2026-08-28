-- All measures in mm

local type = "plug" -- "cover" or "plug"

local pipe_outer_diameter = 26
local pipe_wall_thickness = 2
local cap_wall_thickness = 3
local pad_thickness = 5 -- Thickness of the end part of the cap
local height = 20       -- Distance from end of pipe to end of cap
local rounding = 3      -- Radius of the edge of the cap

local eps = 0.01 -- Used to prevent z-fighting

--------------------------------------------------------------------------------

local cap_outer_rad = (pipe_outer_diameter / 2) + cap_wall_thickness
local cap_inner_rad = pipe_outer_diameter / 2
local pipe_inner_rad = cap_inner_rad - pipe_wall_thickness

local function ring(h, outer_r, inner_r)
  h = h or 2
  outer_r = outer_r or 10
  inner_r = inner_r or 5
  return cylinder(h, outer_r)
    - cylinder(h + (2 * eps), inner_r):translate(0, 0, -eps)
end

local function cut_off_cube(area, size)
  size = size or 10
  local block = cube{{size, size, size}, center = true}
  if area == "positive-z" then
    return block:translate(0, 0, -size / 2)
  elseif area == "negative-z" then
    return block:translate(0, 0, -size / 2)
  elseif area == "positive-x" then
    return block:translate(-size / 2, 0, 0)
  elseif area == "negative-x" then
    return block:translate(size / 2, 0, 0)
  elseif area == "positive-y" then
    return block:translate(0, -size / 2, 0)
  elseif area == "negative-y" then
    return block:translate(0, size / 2, 0)
  end
end

local function outer_body()
  -- Move to touch xy plane
  return (
    cylinder(height + pad_thickness, cap_outer_rad - rounding)
      :minkowski(sphere(rounding))
    - cylinder(height, cap_outer_rad + eps)
        :translate(0, 0, height + pad_thickness - rounding)
  ):translate(0, 0, rounding)
end

local function outer_hull()
  -- Hollow out the centre
  return outer_body()
    - cylinder(height * 2, cap_inner_rad):translate(0, 0, pad_thickness)
end

local function inner_plug()
  local inner_plug_rad = cap_inner_rad - pipe_wall_thickness

  local function inner_plug_body()
    local inner_plug_h = 2 - cap_inner_rad
    -- Tip of plug
    -- Make inner sphere a little larger
    -- to ensure it presses onto the pipe wall
    local extra_width = pipe_wall_thickness * 0.02
    local tip = sphere{r = inner_plug_rad + extra_width}
      - cube{
          {
            (inner_plug_rad + extra_width) * 2.1,
            (inner_plug_rad + extra_width) * 2.1,
            inner_plug_rad,
          },
          center = true,
        }:translate(0, 0, -(inner_plug_rad / 2) - extra_width)
    return (
      cylinder(inner_plug_h, inner_plug_rad)
      + tip:translate(0, 0, inner_plug_h)
    ):translate(0, 0, pad_thickness - eps)
  end

  -- local function slot()
  --   local solid_bottom_height = 5
  --   local slot_height = (height + pad_thickness) * 1.1
  --   return cube{
  --       {pipe_wall_thickness, cap_inner_rad * 2, slot_height},
  --       center = true,
  --     }:translate(0, 0, (slot_height / 2) + pad_thickness + solid_bottom_height)
  -- end

  return inner_plug_body()
  -- return inner_plug_body() - slot() - slot():rotate(0, 0, 90)
end

-- outer_body()
-- outer_hull()
-- inner_plug()

local function cover()
  -- Add inner slotted pipe to clamp onto pipe wall
  return outer_hull() + inner_plug()
end

local function plug()
  -- Add inner slotted pipe to clamp onto pipe wall
  return outer_body() + inner_plug()
end

local function half_plug(wedge_thickness, wedge_angle, tolerance)
  wedge_thickness = wedge_thickness or 1
  wedge_angle = wedge_angle or 2
  tolerance = tolerance or 0.2 -- Make plug slightly smaller for easier insertion
  return (
    (
      outer_body()
      - ring(
          height * 1.1,
          cap_outer_rad * 2,
          pipe_inner_rad
        ):translate(0, 0, pad_thickness)
    ):rotate(0, 90 - wedge_angle, 0)
    - cut_off_cube("negative-z", height * 5)
        :translate(0, 0, (wedge_thickness + tolerance) / 2)
  ):translate(0, 0, -(wedge_thickness + tolerance) / 2)
end

-- // Must be printed vertically for best layer orientation
-- local function wedge_shape(wedge_width, wedge_depth, wedge_thickness, wedge_angle)
--   wedge_width = wedge_width or 10
--   wedge_depth = wedge_depth or 50
--   wedge_thickness = wedge_thickness or 1
--   wedge_angle = wedge_angle or 2
--   return cube{
--       {wedge_thickness / 2, wedge_depth, wedge_width},
--       center = true,
--     }:translate(0, 0, wedge_width / 2)
-- end

if type == "cover" then
  render(cover())
else
  local minimum_wedge_thickness = pipe_wall_thickness * 0.5
  local wedge_thickness = pipe_wall_thickness * 1.1
  local wedge_angle = 2

  local wedge_block =
    cube{{
      pipe_inner_rad * 2,
      height + pad_thickness,
      minimum_wedge_thickness,
    }}
    + bosl.wedge{{
        pipe_inner_rad * 2,
        height + pad_thickness,
        (wedge_thickness - minimum_wedge_thickness) / 2,
      }}:translate(0, 0, minimum_wedge_thickness - eps)
    + bosl.wedge{{
        pipe_inner_rad * 2,
        height + pad_thickness,
        (wedge_thickness - minimum_wedge_thickness) / 2,
      }}:translate(0, 0, -eps):mirror(0, 0, 1)

  render(
    half_plug(wedge_thickness, wedge_angle)
    + half_plug(wedge_thickness, wedge_angle):translate(-2 * height, 0, 0)
    + wedge_block:rotate(0, -90, 0):translate(-5, -15, 0)
  )
end