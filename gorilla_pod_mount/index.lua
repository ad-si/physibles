-- This should be printed with following settings for better strength:
-- - Seam position: Nearest
-- - 5 walls
-- - 25% infill density
-- - honeycomb infill pattern
-- The screw thread might be too tight -> adjust the thread diameter.

local fn = 50

local length = 40
local width_base = 33
local width_tip = 27
local depth_range = { 3.1, 2.7 } -- TODO: Implement long slope
local complete_depth = 6
local short_slope_length = 8.5
local short_slope_angle = 12
local shaft_length = 10
local shaft_diameter = 15.875 -- 5/8 inch
local thread_pitch = 0.94 -- 27 threads/inch
local thread_length = 8
local hole_diameter = 8
local hole_bottom_wall = 2 -- Hole stops this far above the bottom

local function base_plate_half()
  return (
    polygon{
      { 0, 0 }, { length, 0 },
      { length - 8, width_tip / 2 }, { 0, width_tip / 2 },
    }
    -- Corner ~~ (length, 11.5)
    + circle{r = 4, fn = fn}:translate(length - 4, 7.5, 0)
  ):hull()
    + polygon{
        { 0, 0 }, { length, 0 },
        { length - 11, width_tip / 2 }, { 0, width_base / 2 },
      }
end

local function base_plate()
  return base_plate_half() + base_plate_half():mirror(0, 1, 0)
end

local function top_plate_half()
  return (
    polygon{ { 0, 0 }, { length, 0 }, { 0, 12 } }
    -- Corner ~~ (length, 8)
    + circle{r = 5, fn = fn}:translate(length - 5, 3.5, 0)
  ):hull()
end

local function top_plate()
  return top_plate_half() + top_plate_half():mirror(0, 1, 0)
end

local function adapter_without_gap()
  return base_plate():linear_extrude(depth_range[2])
    -- Subtract short slope in the front
    - cube{{20, width_base, depth_range[2]}}
        :rotate(0, short_slope_angle, 0)
        :translate(length - short_slope_length, -width_base / 2, depth_range[2])
    + top_plate():linear_extrude(complete_depth)
end

local function bottom_gap()
  return polygon{
      { length - 1, -1 }, { length - 1, 0 }, { length - 1.5, 3 },
      { length - 6, 0 }, { length - 6, -1 },
    }
    :linear_extrude(10)
    :rotate(90, 0, 0)
    :translate(0, 5, 0)
end

local function gorillapod_adapter()
  return adapter_without_gap() - bottom_gap()
end

local function thread()
  -- Extra rod length buried in the shaft, so union leaves no seam
  local overlap = 1
  local rod_length = thread_length + overlap
  local rod_top = shaft_length + complete_depth + thread_length

  return (
    bosl.threaded_rod{
      d = shaft_diameter,
      pitch = thread_pitch,
      l = rod_length,
      -- Thread runs all the way to the top; the chamfer alone
      -- trims the tip for easier insertion (no thread lead-in fade,
      -- which visibly widened the groove near the top).
      bevel2 = true,
      fn = fn,
    }:translate(0, 0, rod_top - rod_length / 2)
    + cylinder{
        d = shaft_diameter,
        h = shaft_length + complete_depth,
        fn = fn,
      }
  ):translate(18, 0, 0)
end

-- Blind hole down the center of the shaft,
-- stopping `hole_bottom_wall` above the bottom
local function center_hole()
  local top = shaft_length + complete_depth + thread_length
  return cylinder{
      d = hole_diameter,
      h = top - hole_bottom_wall + 1, -- +1 to cut cleanly through the top
      fn = fn,
    }
    :translate(18, 0, hole_bottom_wall)
end

-- Cut off 2 mm from the end to make it protrude less
local model = gorillapod_adapter()
  - cube{{10, width_base * 2, complete_depth * 3}, center = true}
      :translate(-3, 0, 0)
  + thread()
  - center_hole()

render(model)
