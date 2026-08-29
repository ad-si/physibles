local fn = 64
-- `fn` counts facets for the *full* sphere, but the recess only uses a ~35°
-- cap of it, so at fn = 64 the cap is a handful of ~50 mm tiles with 0.6 mm
-- deep dips. 1° steps keep the facet deviation on r = 500 under 0.02 mm.
local recess_fn = 360

local surface_radius = 500
-- Constrained by image size of icon. Actual size (58 mm) must be set in slicer.
local medal_diameter = 300

local function base()
  local cylinder_height = 100 -- Real height is constrained by curvature of recess below it
  local height_above_0 = 1 -- For unioning it
  return cylinder{ h = cylinder_height, d = medal_diameter, fn = fn }
      :translate(0, 0, -cylinder_height + height_above_0)
    - sphere{ r = surface_radius, fn = recess_fn }
        :translate(0, 0, -surface_radius)
end

-- Chamfer instead of rounded edge for better printability
local function emblem()
  local emblem_height = 10
  local chamfer_offset = 6

  -- Inverted heights are negative (white = -100, black = 0), so the
  -- +5 translate together with the 0.05 scale maps the relief to 0..5.
  local heightmap = surface{ "surface@2x.png", center = true, invert = true }
    :scale(1, 1, 0.05)
    :translate(0, 0, 5)

  local chamfer = cylinder{
    h = emblem_height - chamfer_offset,
    d1 = medal_diameter,
    d2 = medal_diameter - 2 * (emblem_height - chamfer_offset),
    fn = fn,
  }

  return (heightmap * chamfer):translate(0, 0, chamfer_offset)
    + cylinder{ h = chamfer_offset, d = medal_diameter, fn = fn }
end

local model = (emblem() + base())
  -- Make it easier to handle. Exact size is set in slicer.
  :scale(0.5, 0.5, 1)

render(model)
