local Vec = require("scenario_toolbox/lua/cubic_vector")

Hex = {}
Hex.__index = Hex

function Hex:new(map, x, y, terrain)
  return setmetatable({ map = map, x = x, y = y, terrain = terrain }, self)
end

function Hex:translate(v)
  return self.map:get(v:translate(self.x, self.y))
end

function Hex:circle(radius)
  return map(function(v) return self:translate(v) end, Vec.equidistant(radius))
end

function Hex:show()
  return self.terrain
end

function Hex:__tostring()
  return string.format("(%d, %d)[%s]", self.x, self.y, self.terrain)
end

function Hex:on_border()
  local dir = ""
  if self.x == 0 then
    dir = "n"
  end
  if self.x == self.map.width + 1 then
    dir = "s"
  end
  if self.y == 0 then
    dir = dir .. "w"
  end
  if self.y == self.map.height + 1 then
    dir = dir .. "e"
  end
  if dir == "" then
    return nil
  else
    return dir
  end
end

function Hex:as_vec()
  return Vec.new(self.y - mathx.floor(self.x / 2), self.x)
end

function Hex:distance(other)
  return (self:as_vec() - other:as_vec()):length()
end

Hex.Set = {}
Hex.Set.__index = Hex.Set

function Hex.Set:new(hexes)
  local this = setmetatable({}, self)
  for hex in hexes or function() end do
    this:add(hex)
  end
  return this
end

function Hex.Set:add(hex)
  if self[hex.x] then
    self[hex.x][hex.y] = hex
  else
    self[hex.x] = { [hex.y] = hex }
  end
end

function Hex.Set:remove(hex)
  if self[hex.x] then
    self[hex.x][hex.y] = nil
  end
end

function Hex.Set.member(hex)
  if self[hex.x] then
    return self[hex.x][hex.y] and true or false
  else
    return false
  end
end

function Hex.Set:iter_rows()
  local x, row = nil
  return function()
    x, row = next(self, x)
    return row
  end
end

function Hex.Set:iter()
  local function iterate(row)
    local i, item = nil
    return function()
      i, item = next(row, i)
      return item
    end
  end
  return join(map(iterate, self:iter_rows()))
end

function Hex.Set:empty()
  for _ in self:iter() do
    return false
  end
  return true
end

function Hex.Set:size()
  return fold(arith.add, 0, map(function(_) return 1 end, self:iter()))
end

return Hex
