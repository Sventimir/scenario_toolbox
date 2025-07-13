local Vec = require("scenario_toolbox/lua/map/cubic_vector")
local Predicate = require("scenario_toolbox/lua/lib/predicate")

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

function Hex:in_circle(radius)
  return chain(iter({ self }), join(map(function(r) return self:circle(r) end, take(radius, arith.nats()))))
end

function Hex:show()
  return self.terrain
end

function Hex:__tostring()
  return string.format("(%d, %d)[%s]", self.x, self.y, self.terrain)
end

function Hex:__equal(other)
  return self.x == other.x and self.y == other.y
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
    if not self[hex.x][hex.y] then
      self[hex.x][hex.y] = hex
      self.size = self.size + 1
    end
  else
    self[hex.x] = { [hex.y] = hex }
    self.size = self.size + 1
  end
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

function Hex.Set:member(hex)
  if self[hex.x] then
    return self[hex.x][hex.y] and true or false
  else
    return false
  end
end

function Hex.Set:memeber_pred()
  return Predicate:func(function(x) return self:member(x) end)
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

function Hex.Set:intersect(other)
  local sets = { self, other }
  table.sort(sets, function(a, b) return a.size < b.size end)
  return Hex.Set:new(filter(function(h) return sets[2]:member(h) end, sets[1]:iter()))
end

function Hex.Set:diff(other)
  return Hex.Set:new(filter(function(h) return not other:member(h) end, self:iter()))
end

function Hex.Set:union(other)
  return Hex.Set:new(chain(self:iter(), other:iter()))
end

return Hex
