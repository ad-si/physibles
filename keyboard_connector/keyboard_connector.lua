-- Keyboard connector for a Keebio Iris CE split keyboard
--
-- A flat bracket that joins the two splayed halves into one rigid
-- unit. It lies on the desk between them: a W-shaped band runs under
-- both halves' bottom edges, and per side three features grip the
-- keyboard half:
--   - a corner seat (a long edge along the keyboard's inner edge,
--     meeting a perpendicular ledge) takes the bottom inner corner,
--   - a stepped seat follows the bottom edge where the thumb cluster
--     juts below the main body,
--   - an end finger sticks up past the bottom outer corner and stops
--     the half sliding outward.
-- A prong rises between seat and step on each side; the middle prongs
-- flank the gap where the halves' link cable runs.
--
-- The outline is symmetric: one half is modeled (as in the Fusion
-- model this is recreated from, exported as "Connector Half.3mf") and
-- mirrored about its flat joint face for the full part.
--
-- The two pieces are joined by a hinge along the joint face:
-- alternating barrel knuckles, with a strand of 1.75 mm filament
-- threaded through as the axle. The barrel axis lies on the top
-- face, so the joint folds through a full 180 degrees: one piece
-- swings up and over and comes to rest flat on top of the other.
-- The barrel therefore stands proud of the top face; a 45-degree V
-- under it supports the overhang when printing flat. Mirroring does
-- not move the knuckles along the edge, so the pieces are no longer
-- interchangeable: the right piece owns the odd knuckle segments
-- (both ends), the left the even ones. "both" lays them out side by
-- side so one export prints the pair.
--
-- The outline is one closed loop of straight edges, filleted at every
-- corner. The edges were traced over a photo of the keyboard halves
-- (original.png), hence the odd corner coordinates and edge angles.
--
-- All measures in mm

-- "half": the right piece alone
-- "both": right and left piece laid out for printing in one go
-- "full": the two pieces joined at x = 0, as assembled
local part = "full"

local height = 5 -- Extrusion height (z)

-- Hinge along the joint face
local knuckle_count = 5 -- Alternating between the pieces, odd ones right
local barrel_r = height / 2 -- Knuckle barrel radius, axis on the top face
local axle_hole_d = 2.2 -- Hole for the 1.75 mm filament axle
local hinge_gap = 0.3 -- Clearance between knuckles and around the barrel

-- Corner points of the half's outline, counterclockwise, with the
-- fillet radius rounding each corner (sharp where omitted). x = 0 is
-- the joint face to the mirrored half; y points away from the typist.
-- The corners are where adjacent edges would intersect; the fillets
-- are tangent arcs computed below.
local corners = {
  { 0, 0 }, -- Joint face, top
  { 0, -30 }, -- Joint face, bottom
  -- Outer boundary: the band's near side dips under the keyboard half
  -- in three straight runs, then rounds the outer end of the finger
  { 28.9672, -30, r = 20 },
  { 63.1085, -64.222, r = 20 }, -- Bottom of the dip
  { 96.3473, -33.9726, r = 20 },
  { 135.3564, -24.7217, r = 20 }, -- Outer end, below the finger
  { 128.162, 5.6156, r = 2 }, -- Tip of the end finger
  -- Stepped seat under the keyboard's bottom edge: main-body level,
  -- a 12.5 drop, then the thumb-cluster level
  { 112.2046, 1.8313, r = 2 },
  { 116.2398, -15.1844, r = 3 },
  -- Wide concave sweep from the step across to the inner-edge seat
  { 81.5825, -23.4033, r = 45.9647 },
  { 63.611, -39.819, r = 3 },
  -- Corner seat: the 38 long edge lies along the keyboard's inner
  -- edge, the perpendicular ledge under its bottom inner corner
  { 33.9363, -7.332, r = 3 },
  { 47.2264, 4.8077, r = 3 },
  { 32.1784, 21.2818, r = 20 }, -- Tip of the middle prong
  { 8.8797, 0, r = 10 }, -- Back at the top edge, y = 0
}

--------------------------------------------------------------------------------

-- Append a point, skipping consecutive duplicates
local function add(pts, x, y)
  local last = pts[#pts]
  if last and math.abs(last[1] - x) < 1e-6 and math.abs(last[2] - y) < 1e-6 then
    return
  end
  pts[#pts + 1] = { x, y }
end

-- Expand the corner list into the outline: each corner with a radius
-- becomes the arc tangent to both adjacent edges, tessellated to a
-- 0.005 mm sagitta; sharp corners pass through unchanged
local function rounded_outline(cs)
  local pts = {}
  for i, c in ipairs(cs) do
    local x, y, r = c[1], c[2], c.r
    if not r then
      add(pts, x, y)
    else
      local p = cs[i == 1 and #cs or i - 1]
      local n = cs[i == #cs and 1 or i + 1]
      -- Unit vectors from the corner along both edges
      local ux, uy = p[1] - x, p[2] - y
      local vx, vy = n[1] - x, n[2] - y
      local ul = math.sqrt(ux * ux + uy * uy)
      local vl = math.sqrt(vx * vx + vy * vy)
      ux, uy, vx, vy = ux / ul, uy / ul, vx / vl, vy / vl
      -- Tangent points sit `r / tan(half angle)` from the corner, the
      -- arc's center on the bisector; the arc sweeps the corner's
      -- exterior turn, in the turn's direction
      local half_angle = math.acos(ux * vx + uy * vy) / 2
      local t = r / math.tan(half_angle)
      local bx, by = ux + vx, uy + vy
      local bl = math.sqrt(bx * bx + by * by)
      local cx = x + bx / bl * r / math.sin(half_angle)
      local cy = y + by / bl * r / math.sin(half_angle)
      local sx, sy = x + ux * t - cx, y + uy * t - cy
      local sweep = math.pi - 2 * half_angle
      if uy * vx - ux * vy < 0 then
        sweep = -sweep
      end
      local step = 2 * math.acos(1 - math.min(1, 0.005 / r))
      local steps = math.max(1, math.ceil(math.abs(sweep) / step))
      for k = 0, steps do
        local a = sweep * k / steps
        local cos_a, sin_a = math.cos(a), math.sin(a)
        add(pts, cx + sx * cos_a - sy * sin_a, cy + sx * sin_a + sy * cos_a)
      end
    end
  end
  return pts
end

local outline = rounded_outline(corners)

local half = polygon { points = outline }
  :linear_extrude(height)

-- The joint edge runs from corners[1] down to corners[2], split into
-- knuckle_count equal segments. Each piece owns every other segment:
-- the plate is first cut back around the other piece's knuckles (so
-- they can turn), then this piece's barrels are added on the edge,
-- and the axle hole is drilled along the whole edge.
local joint_len = -corners[2][2]
local seg_len = joint_len / knuckle_count

local function hinged(owns_odd)
  local piece = half
  for i = 1, knuckle_count do
    local y_top = -(i - 1) * seg_len
    if (i % 2 == 1) ~= owns_odd then
      -- Groove for the other piece's knuckle: a cylindrical bite
      -- around the axis rather than a full-depth notch. The plate
      -- keeps a tongue below the groove that runs under the other
      -- piece's barrel, so the assembled joint is closed underneath.
      -- The tongue additionally gets a V-groove clearing the V that
      -- supports the other piece's barrel: that V pokes past the
      -- barrel's swept envelope across the joint plane, deepest when
      -- the joint lies flat (folding only pulls it back). The
      -- groove's walls rise from the V ridge's height on the joint
      -- plane (so the bank's bottom edge lines up with the V ridges
      -- and, when the joint lies flat, meets the other piece's ridge
      -- the way the joint faces meet) to where they are tangent to
      -- the bite, blending into its cylindrical wall without a
      -- crease. The bank is shallower than the V's 45-degree faces,
      -- so it pulls away from them off the joint plane, and folding
      -- only moves the V back to its own side. Below the groove the
      -- tongue ends in a vertical face on the joint plane, matching
      -- the plate's joint face under its own V supports.
      local ridge = height - barrel_r * math.sqrt(2)
      local bite_r = barrel_r + hinge_gap
      -- Tangent point of the bank from the ridge to the bite circle
      local dist = height - ridge
      local tan_len = math.sqrt(dist * dist - bite_r * bite_r)
      local tan_x = tan_len * bite_r / dist
      local tan_z = ridge + tan_len * tan_len / dist
      piece = piece
        - cylinder { h = seg_len + hinge_gap, r = bite_r, fn = 64 }
          :rotate(90, 0, 0)
          :translate(0, y_top + hinge_gap / 2, height)
        - polygon {
          points = {
            { 0, ridge },
            { tan_x, tan_z },
            { tan_x, height + barrel_r },
            { -tan_x, height + barrel_r },
            { -tan_x, tan_z },
          },
        }
          :linear_extrude(seg_len + hinge_gap)
          :rotate(90, 0, 0)
          :translate(0, y_top + hinge_gap / 2, 0)
    end
  end
  for i = 1, knuckle_count do
    local y_top = -(i - 1) * seg_len
    if (i % 2 == 1) == owns_odd then
      -- Flush with the plate's outer corners, set back by half the
      -- gap where the neighboring knuckle belongs to the other piece
      local ya = y_top - (i > 1 and hinge_gap / 2 or 0)
      local yb = y_top - seg_len + (i < knuckle_count and hinge_gap / 2 or 0)
      -- The V under the barrel: its two 45-degree faces are tangent
      -- to the barrel and meet in a ridge on the plate's joint face,
      -- so the barrel's underside prints without steep overhangs.
      -- Below the tangent points it reaches outside the barrel's
      -- swept envelope, but only ever toward its own side of the
      -- joint plane, so it clears the other piece at every fold
      -- angle and merely rests against its tongue when lying flat.
      local vee = barrel_r * math.sqrt(2) / 2
      piece = piece
        + cylinder { h = ya - yb, r = barrel_r, fn = 64 }
          :rotate(90, 0, 0)
          :translate(0, ya, height)
        + polygon {
          points = {
            { 0, height - 2 * vee },
            { vee, height - vee },
            { -vee, height - vee },
          },
        }
          :linear_extrude(ya - yb)
          :rotate(90, 0, 0)
          :translate(0, ya, 0)
    end
  end
  -- The axle hole is teardrop-shaped: a 45-degree peak on top of
  -- the round hole, so its ceiling prints without sagging bridges
  local peak = axle_hole_d / 2 * math.sqrt(2) / 2
  return piece
    - (
      cylinder { h = joint_len + 2, r = axle_hole_d / 2, fn = 32 }
      + polygon {
        points = { { -peak, peak }, { peak, peak }, { 0, 2 * peak } },
      }:linear_extrude(joint_len + 2)
    )
      :rotate(90, 0, 0)
      :translate(0, 1, height)
end

local right = hinged(true)
local left = hinged(false):mirror(1, 0, 0)

-- The pieces are rendered separately so they stay distinct objects
-- in the export instead of merging into one mesh.
if part == "half" then
  render(right)
elseif part == "full" then
  render(right)
  render(left)
else
  -- The left piece, shifted back into positive x and placed one
  -- footprint depth plus a gap behind the right piece
  local max_x, min_y, max_y = 0, math.huge, -math.huge
  for _, p in ipairs(outline) do
    max_x = math.max(max_x, p[1])
    min_y = math.min(min_y, p[2])
    max_y = math.max(max_y, p[2])
  end
  render(right)
  render(left:translate(max_x, -(max_y - min_y + 10), 0))
end
