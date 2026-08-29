local fn = 50

local edge_length = 50
local max_height = 100

-- 0: Empty
-- 1: Pawn
-- 2: Rook
-- 3: Knight
-- 4: Bishop
-- 5: Queen
-- 6: King
--
-- Color white: + 10
-- Color black: + 20
local setup = {
  { 12, 13, 14, 16, 15, 14, 13, 12 },
  { 11, 11, 11, 11, 11, 11, 11, 11 },
  { 0, 0, 0, 0, 0, 0, 0, 0 },
  { 0, 0, 0, 0, 0, 0, 0, 0 },
  { 0, 0, 0, 0, 0, 0, 0, 0 },
  { 0, 0, 0, 0, 0, 0, 0, 0 },
  { 21, 21, 21, 21, 21, 21, 21, 21 },
  { 22, 23, 24, 26, 25, 24, 23, 22 },
}

local function pawn(x, y)
  local height = 0.5 * max_height

  return cylinder{ d1 = edge_length * 0.5, d2 = 20, h = height, fn = fn }
    :translate(x, y, 0)
end

local function rook(x, y)
  local height = 0.6 * max_height
  local size_vector = { edge_length, edge_length * 0.08, 10 }

  local battlements = cube{ size_vector, center = true }
    + cube{ size_vector, center = true }:rotate(0, 0, 60)
    + cube{ size_vector, center = true }:rotate(0, 0, 120)
    + cylinder{ d = edge_length * 0.3, h = 10, center = true, fn = fn }

  return (
    cylinder{
      d1 = edge_length * 0.6,
      d2 = edge_length * 0.5,
      h = height,
      fn = fn,
    }
    - battlements:translate(0, 0, height)
  ):translate(x, y, 0)
end

local function knight(x, y)
  local height = 0.7 * max_height

  return cylinder{ d = edge_length * 0.6, h = height, fn = fn }
    :translate(x, y, 0)
end

local function bishop(x, y)
  local height = 0.8 * max_height

  return cylinder{
      d1 = edge_length * 0.6,
      d2 = edge_length * 0.2,
      h = height,
      fn = fn,
    }
    :translate(x, y, 0)
end

local function queen(x, y)
  local height = 0.9 * max_height

  return cylinder{
      d1 = edge_length * 0.6,
      d2 = edge_length * 0.4,
      h = height,
      fn = fn,
    }
    :translate(x, y, 0)
end

local function king(x, y)
  local height = max_height

  return cylinder{
      d1 = edge_length * 0.6,
      d2 = edge_length * 0.4,
      h = height,
      fn = fn,
    }
    :translate(x, y, 0)
end

local pieces = { pawn, rook, knight, bishop, queen, king }

local function chessboard()
  local height = 10
  local board

  for x = 0, 7 do
    for y = 0, 7 do
      local value = setup[y + 1][x + 1]
      local square_color = ((x + y) % 2 == 0)
        and { 0, 0, 0, 1 }
        or { 1, 1, 1, 1 }

      local square = cube{ { edge_length, edge_length, height } }
        :translate(x * edge_length, y * edge_length, -height)
        :color(square_color)
      board = board and (board + square) or square

      local piece = pieces[value % 10]
      if piece then
        local figure_color = (value - 20) < 0
          and { 0.92, 0.9, 0.85, 1 }
          or { 0.2, 0.15, 0.1, 1 }

        board = board + piece(
          x * edge_length + edge_length / 2,
          y * edge_length + edge_length / 2
        ):color(figure_color)
      end
    end
  end

  return board
end

render(chessboard())
