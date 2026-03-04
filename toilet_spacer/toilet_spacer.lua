-- Toilet Spacer

-- Outer dimensions: 22 mm * 52 mm * 6 mm
-- Inner dimensions: 11 mm * 38 mm * 7 mm

local outer_length = 52
local outer_width = 22
local outer_height = 6
local outer_vertical_wall = 2

local inner_length = 38
local inner_width = 11
local inner_height = 7
local inner_vertical_wall = 5


function half_pill_shape (length, width, height, vertical_wall)
  local large_radius = width/2
  local bottom_radius = height - vertical_wall
  local straight_edge_length = length - (2*large_radius) - (2*bottom_radius)

  -- Double everything as its centered and will be halved later
  local pill_shape =
    cylinder{h=2*vertical_wall, r=width/2 - bottom_radius, center = true}
    + cube{
        width - 2*bottom_radius,
        straight_edge_length,
        2*vertical_wall,
        center=true
      }
      :translate(0, straight_edge_length/2, 0)
    + cylinder{h=2*vertical_wall, r=width/2 - bottom_radius, center = true}
        :translate(0, straight_edge_length, 0)

  return
    (
      pill_shape
        :minkowski(sphere(bottom_radius))
      - cube{999,999,999, center=true}:translate(0,0,999/2)
    )
      :translate(0, -straight_edge_length/2, 0)
end

local spacer =
  half_pill_shape(outer_length, outer_width, outer_height, outer_vertical_wall)
  + half_pill_shape(inner_length, inner_width, inner_height, inner_vertical_wall)
      :rotate(0,180,0)

render(spacer)
