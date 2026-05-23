local Vec = require("scenario_toolbox/lua/map/cubic_vector")
local Predicate = require("scenario_toolbox/lua/lib/predicate")

local Base = {}
local __Base = { __index = Base }

function Base.map_size(x, y)
  return { width = y and x or x.width or x.x, height = y or x.height or x.y }
end

function Base.new(x, y)
  return setmetatable({ x = x, y = y }, __Base)
end

function Base:equals(other)
  return self.x == other.x and self.y == other.y
end

function Base:as_vec()
  return Vec.new(self.y - mathx.floor(self.x / 2), self.x)
end

function Base:translate(v)
  return Base.new(v:translate(self.x, self.y))
end

function Base:circle(r)
  return map(function(v) return self:translate(v) end, Vec.equidistant(r))
end

function Base:adjacent()
  return self:circle(1)
end

function Base:in_circle(radius)
  return chain(iter({ self }), join(map(function(r) return self:circle(r) end, take(radius, arith.nats()))))
end

function Base:distance(hex)
  return (self:as_vec() - hex:as_vec()):length()
end

function Base:on_map(width, height)
  local size = self.map_size(width, height)
  return self.x > 0 and self.x <= size.width and self.y > 0 and self.y <= size.height
end

function Base:is_border(width, height)
  local size = self.map_size(width, height)
  return self.x == 0 or self.y == 0 or self.x == size.width + 1 or self.y == size.height + 1
end

function Base:border_distance(width, height)
  local size = self.map_size(width, height)
  return mathx.min(self.x, self.y, size.width - self.x + 1, size.height - self.y + 1)
end

function __Base:__tostring()
  return string.format("(%d, %d)", self.x, self.y)
end

function __Base:__equal(other)
  return self:equals(other)
end

function Base.from_wesnoth(hex)

  function hex:translate(v)
    return Base.from_wesnoth(wesnoth.map.get(v:translate(self.x, self.y)))
  end

  hex.equals = Base.equals
  hex.coords = Base.coords
  hex.circle = Base.circle
  hex.in_circle = Base.in_circle
  hex.as_vec = Base.as_vec
  hex.distance = Base.distance
  hex.__tostring = Base.__tostring

  return hex
end

local Hex = setmetatable({}, __Base)
local __Hex = { __index = Hex, __tostring = __Base.__tostring, __equal = __Base.__equal }

function Hex.new(map, x, y, biome)
  local this = {
      map = map,
      x = x,
      y = y,
      height = nil,
      terrain = "",
      overlays = biome.overlay,
  }

  if this.x > 0 and this.x <= map.width and this.y > 0 and this.y <= map.height then
    biome:add_hex(this)
  end
  return setmetatable(this, __Hex)
end

function Hex:coords()
  return { x = self.x, y = self.y }
end

function Hex:get_height()
  return mathx.round(self.height)
end

function Hex:get_terrain()
  if self.terrain == "" then
    local start = self.starting_location and string.format("%d ", self.starting_location) or ""
    self.terrain = start .. (self.overlay or id)(self.biome.terrain[self:get_height()])
  end
  return self.terrain
end

function Hex:show()
  return self.terrain
end

function Hex:set_label(text, colour)
  self.__label = { text = text, colour = colour }
end

function Hex:label()
  if self.__label then
    return wml.merge(self.__label, self:coords())
  end
end

function Hex:has_feature(name)
  return self.feature and (not name or self.feature.name == name)
end

function Hex:at_night()
  local schedule = wesnoth.schedule.get_time_of_day(self)
  return schedule.lawful_bonus < 0
end

function Hex:has_forest()
  return self.overlay and self.overlay.name == "forest"
end

function Hex:has_village()
  return self.overlay and self.overlay.name == "village"
end

function Hex:is_water()
  local t = self.biome.terrain[self:get_height()]
  return string.find(t, "^W") or string.find(t, "^Ss")
end

function Hex:is_keep()
  return self.overlay and self.overlay.name == "keep"
end

function Hex:is_castle()
  return self.overlay and self.overlay.name == "castle"
end

function Hex:translate(v)
  local h = Base.translate(self, v)
  return self.map:get(h.x, h.y)
end

function Hex:border_distance()
  return Base.border_distance(self, self.map)
end

function Hex:circle(r)
  return filter_map(function(h) return self.map:get(h.x, h.y) end, Base.circle(self, r))
end

Hex.Set = {}

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

function Hex.Set:remove(...)
  local hex = wesnoth.map.read_location(...)
  if self[hex.y] then
    local h = self[hex.y][hex.x]
    if h then self.size = self.size - 1 end
    self[hex.y][hex.x] = nil
    return h
  end
end

function Hex.Set:random()
  if self.size < 1 then
    error("Cannot pick from an empty hex-set!")
  end
  local it = drop(mathx.random(0, self.size - 1), self:iter())
  return it()
end

function Hex.Set:pop_random()
  local h = self:random()
  self:remove(h)
  return h
end

function Hex.Set:get(x, y)
  local loc = wesnoth.map.read_location(x, y)
  if self[loc.y] then
    return self[loc.y][loc.x]
  end
end

function Hex.Set:member(x, y)
  return self:get(x, y) and true or false
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

function Hex.Set:member_pred()
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

function Hex.Set:partition(f)
  local results = {}
  for hex in self:iter() do
    local key = f(hex)
    if not results[key] then
      results[key] = Hex.Set:new()
    end
    results[key]:add(hex)
  end
  return results
end

function Hex.Set:wml(tag)
  local contents = {}
  for hex in self:iter() do
    table.insert(contents, wml.tag[tag or "hex"](hex))
  end
  return contents
end

function Hex.Set:from_wml(spec)
  local hset = self:new()
  for tag in iter(spec) do
    hset:add(tag[2])
  end
  return hset
end

return Hex
