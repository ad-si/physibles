-- Fan mount for the Kossel 3D printer
-- All measures in mm

local fan_edge_length = 40
local fan_depth = 10
local fan_diameter = 38

local show_fan = false -- Render a reference model of the fan for fit checking

local fn = 50
local eps = 0.01 -- Used to prevent z-fighting

--------------------------------------------------------------------------------

-- Reference model of the fan (not part of the print)
local function fan(edge_length, depth, diameter)
  local screw_hole_diameter = 3
  local screw_hole_offset = 3

  local function screwhole()
    return cylinder{h = 2 * depth, d = screw_hole_diameter, fn = fn}
      :translate(
        screw_hole_diameter / 2 + screw_hole_offset,
        screw_hole_diameter / 2 + screw_hole_offset,
        -(depth * 0.5)
      )
  end

  local screwholes = screwhole()
    + screwhole():mirror(1, 0, 0):translate(edge_length, 0, 0)
    + screwhole():mirror(0, 1, 0):translate(0, edge_length, 0)
    + screwhole():mirror(1, 1, 0):translate(edge_length, edge_length, 0)

  return cube{{edge_length, edge_length, depth}}
    - screwholes
    - cylinder{h = 2 * depth, d = diameter, fn = fn}
        :translate(edge_length / 2, edge_length / 2, -(depth * 0.5))
end

local function mount()
  local bridge_height = 12
  local bridge_width = 60
  local bridge_depth = 5
  local horn_height = 10

  local screw_hole_diameter = 3
  local screw_hole_offset = 3

  local inaccuracy_correction = 0.4

  local body =
    -- Bridge
    cube{
      {bridge_width, bridge_height + horn_height, bridge_depth * 2},
      center = true,
    }:translate(0, -bridge_height / 2 + horn_height / 2, 0)
    -- Outer cone
    + cylinder{
        h = 10,
        d1 = fan_diameter,
        d2 = fan_diameter + 20,
        center = true,
        fn = fn,
      }:translate(0, -fan_edge_length / 2, 0)

  local cutoffs =
    cube{
      {bridge_width - 2 * bridge_depth, 18 * 2, bridge_depth * 2},
      center = true,
    }:translate(0, 0, -bridge_depth)
    + cube{
        {fan_edge_length + 10, bridge_height * 2, bridge_depth * 4},
        center = true,
      }:translate(0, bridge_height, 0)
    + cube{
        {bridge_width * 2, bridge_height * 2, bridge_depth * 4},
        center = true,
      }:translate(0, -fan_edge_length - bridge_height, 0)

  local inner_cone = cylinder{
      h = 10 + eps,
      d1 = fan_diameter - 10,
      d2 = fan_diameter,
      center = true,
      fn = fn,
    }:translate(0, -fan_edge_length / 2, 0)

  -- Clearance for the printer part the mount clips onto
  local recess = cylinder{h = 100, r = 10, center = true, fn = fn}
    :rotate(90, 0, 0)
    :translate(0, 0, -10)

  local screw_x = fan_edge_length / 2
    - screw_hole_offset
    - screw_hole_diameter / 2
    + inaccuracy_correction
  local screw_y = -screw_hole_offset - screw_hole_diameter / 2

  local baseplate_screwholes =
    cylinder{h = 20, d = 3, center = true, fn = fn}
      :translate(-screw_x, screw_y, 0)
    + cylinder{h = 20, d = 3, center = true, fn = fn}
        :translate(screw_x, screw_y, 0)

  local fan_screwholes =
    cylinder{h = 20, d = 3, fn = fn}
      :rotate(0, 90, 0)
      :translate(fan_edge_length / 2, screw_y + horn_height, 0)
    + cylinder{h = 20, d = 3, fn = fn}
        :rotate(0, 90, 0)
        :translate(-fan_edge_length / 2 - 20, screw_y + horn_height, 0)

  return body
    - cutoffs
    - inner_cone
    - recess
    - baseplate_screwholes
    - fan_screwholes
end

--------------------------------------------------------------------------------

local model = mount()

if show_fan then
  model = model
    + fan(fan_edge_length, fan_depth, fan_diameter):translate(-20, -40, 5)
end

render(model:mirror(0, 0, 1):translate(0, 0, 5))
