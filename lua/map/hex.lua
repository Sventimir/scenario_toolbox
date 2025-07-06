local Vec = require("scenario_toolbox/lua/map/cubic_vector")

local Hex = {}

function Hex:new(map, x, y, terrain)
  local this = setmetatable({ map = map, x = x, y = y, terrain = terrain }, self)
  self.__index = self
  return this
end

function Hex:from_wesnoth(hex)

  function hex:translate(v)
    return Hex:from_wesnoth(wesnoth.map.get(v:translate(self.x, self.y)))
  end

  hex.circle = Hex.circle
  hex.as_vec = Hex.as_vec
  hex.distance = Hex.distance
  hex.__tostring = Hex.__tostring

  return hex
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
  this.size = 0
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
  self.size = self.size + 1
end

function Hex.Set:remove(hex)
  if self[hex.x] then
    if self[hex.x][hex.y] then
      self.size = self.size - 1
    end
    self[hex.x][hex.y] = nil
  end
end

function Hex.Set:random()
  local it = drop(mathx.random(0, self.size - 1), self:iter())
  return it()
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
    while type(x) == "string" do
      x, row = next(self, x)
    end
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

return Hex
