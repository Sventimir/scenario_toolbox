local Vec = require("scenario_toolbox/lua/map/cubic_vector")
local Predicate = require("scenario_toolbox/lua/lib/predicate")

local Hex = {}

function Hex:new(map, x, y, biome)
  local this = {
      map = map,
      x = x,
      y = y,
      height = nil,
      terrain = ""
  }
  self.__index = self
  if this.x > 0 and this.x <= map.width and this.y > 0 and this.y <= map.height then
    biome:add_hex(this)
  end
  return setmetatable(this, self)
end

function Hex:from_wesnoth(hex)

  function hex:translate(v)
    return Hex:from_wesnoth(wesnoth.map.get(v:translate(self.x, self.y)))
  end

  hex.equals = Hex.equals
  hex.coords = Hex.coords
  hex.circle = Hex.circle
  hex.in_circle = Hex.in_circle
  hex.as_vec = Hex.as_vec
  hex.distance = Hex.distance
  hex.__tostring = Hex.__tostring

  return hex
end

function Hex:coords()
  return { x = self.x, y = self.y }
end

function Hex:equals(other)
  return other and self.x == other.x and self.y == other.y
end

function Hex:translate(v)
  return self.map:get(v:translate(self.x, self.y))
end

function Hex:circle(radius)
  return filter_map(function(v) return self:translate(v) end, Vec.equidistant(radius))
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

function Hex:has_feature(name)
  return self.feature and (not name or self.feature.name == name)
end

function Hex:at_night()
  local schedule = wesnoth.schedule.get_time_of_day(self)
  return schedule.lawful_bonus < 0
end

function Hex:is_border()
  return self.x <= 0 or self.x >= self.map.width
    or self.y <= 0 or self.y >= self.map.height
end

function Hex:has_forest()
  return string.find(self.terrain, "%^F")
end

function Hex:has_village()
  return string.find(self.terrain, "%^V")
end

function Hex:is_keep()
  return string.find(self.terrain, "^K")
end

function Hex:is_castle()
  return string.find(self.terrain, "^C")
end

Hex.Set = {}
Hex.Set.__index = Hex.Set

function Hex.Set:new(hexes, state, ctrl)
  local this = setmetatable({}, { __index = self })
  this.size = 0
  this.max_row = 0
  this.min_row = 0
  if hexes then
    for hex in hexes, state, ctrl do
      this:add(hex)
    end
  end
  return this
end

function Hex.Set:singleton(hex)
  local set = self:new()
  set:add(hex)
  return set
end

function Hex.Set:add(hex)
  if self[hex.y] then
    if not self[hex.y][hex.x] then
      local row = self[hex.y]
      row[hex.x] = hex
      self.size = self.size + 1
      row.min_col = mathx.min(row.min_col, hex.x)
      row.max_col = mathx.max(row.max_col, hex.x)
    end
  else
    self[hex.y] = { [hex.x] = hex, min_col = hex.x, max_col = hex.x }
    self.size = self.size + 1
    self.min_row = mathx.min(self.min_row, hex.y)
    self.max_row = mathx.max(self.max_row, hex.y)
  end
end

function Hex.Set:remove(hex)
  if self[hex.y] then
    if self[hex.y][hex.x] then
      self.size = self.size - 1
    end
    self[hex.y][hex.x] = nil
  end
end

function Hex.Set:random()
  local it = drop(mathx.random(0, self.size - 1), self:iter())
  return it()
end

function Hex.Set:pop_random()
  local h = self:random()
  self:remove(h)
  return h
end

function Hex.Set:get(x, y)
  if self[y] then
    return self[y][x]
  end
end

function Hex.Set:member(hex)
  if self[hex.y] then
    return self[hex.y][hex.x] and true or false
  else
    return false
  end
end

function Hex.Set:as_area()
  local it = self:iter()
  local h = it()
  if not h then return nil end
  local x = string.format("%i", h.x)
  local y = string.format("%i", h.y)
  for h in it do
    x = string.format("%s,%i", x, h.x)
    y = string.format("%s,%i", y, h.y)
  end
  return x, y
end

function Hex.Set:memeber_pred()
  return Predicate:func(function(x) return self:member(x) end)
end

function Hex.Set:iter_rows()
  local y = self.min_row - 1
  return function()
    repeat y = y + 1
    until y >= self.max_row or self[y]
    return self[y]
  end
end

function Hex.Set:iter()
  local function iterate(row)
    local x = row.min_col - 1
    return function()
      repeat x = x + 1
      until x >= row.max_col or row[x]
      return row[x]
    end
  end
  return join(map(iterate, self:iter_rows()))
end

function Hex.Set:empty()
  return self.size == 0
end

function Hex.Set:filter(predicate)
  return Hex.Set:new(filter(predicate, self:iter()))
end

function Hex.Set:intersect(other)
  local sets = { self, other }
  table.sort(sets, function(a, b) return a.size < b.size end)
  return Hex.Set:new(filter(function(h) return sets[2]:member(h) end, sets[1]:iter()))
end

function Hex.Set:diff(other)
  return self:filter(function(h) return not other:member(h) end)
end

function Hex.Set:union(other)
  return Hex.Set:new(chain(self:iter(), other:iter()))
end

return Hex
