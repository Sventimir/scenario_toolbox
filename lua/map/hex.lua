local Vec = require("scenario_toolbox/lua/map/cubic_vector")
local Predicate = require("scenario_toolbox/lua/lib/predicate")

local Mod = {}

Mod.Base = {}
Mod.__Base = { __index = Mod.Base }

function Mod.Base.map_size(x, y)
  return { width = y and x or x.width or x.x, height = y or x.height or x.y }
end

function Mod.Base.new(x, y)
  return setmetatable({ x = x, y = y }, Mod.__Base)
end

function Mod.Base:equals(other)
  return self.x == other.x and self.y == other.y
end

function Mod.Base:as_vec()
  return Vec.new(self.y - mathx.floor(self.x / 2), self.x)
end

function Mod.Base:translate(v)
  return Mod.Base.new(v:translate(self.x, self.y))
end

function Mod.Base:circle(r)
  return map(function(v) return self:translate(v) end, Vec.equidistant(r))
end

function Mod.Base:adjacent()
  return self:circle(1)
end

function Mod.Base:in_circle(radius)
  return chain(iter({ self }), join(map(function(r) return self:circle(r) end, take(radius, arith.nats()))))
end

function Mod.Base:distance(hex)
  return (self:as_vec() - hex:as_vec()):length()
end

function Mod.Base:on_map(width, height)
  local size = self.map_size(width, height)
  return self.x > 0 and self.x <= size.width and self.y > 0 and self.y <= size.height
end

function Mod.Base:is_border(width, height)
  local size = self.map_size(width, height)
  return self.x == 0 or self.y == 0 or self.x == size.width + 1 or self.y == size.height + 1
end

function Mod.Base:border_distance(width, height)
  local size = self.map_size(width, height)
  return mathx.min(self.x, self.y, size.width - self.x + 1, size.height - self.y + 1)
end

function Mod.__Base:__tostring()
  return string.format("(%d, %d)", self.x, self.y)
end

function Mod.__Base:__equal(other)
  return self:equals(other)
end

function Mod.Base.from_wesnoth(hex)

  function hex:translate(v)
    return Mod.Base.from_wesnoth(wesnoth.map.get(v:translate(self.x, self.y)))
  end

  hex.equals = Mod.Base.equals
  hex.coords = Mod.Base.coords
  hex.circle = Mod.Base.circle
  hex.in_circle = Mod.Base.in_circle
  hex.as_vec = Mod.Base.as_vec
  hex.distance = Mod.Base.distance
  hex.__tostring = Mod.Base.__tostring

  return hex
end

Mod.Legacy = setmetatable({}, Mod.__Base)
Mod.__Legacy = { __index = Mod.Legacy, __tostring = Mod.__Base.__tostring, __equal = Mod.__Base.__equal }

function Mod.Legacy.new(map, x, y, biome)
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
  return setmetatable(this, Mod.__Legacy)
end

function Mod.Legacy:coords()
  return { x = self.x, y = self.y }
end

function Mod.Legacy:get_height()
  return mathx.round(self.height)
end

function Mod.Legacy:get_terrain()
  if self.terrain == "" then
    local start = self.starting_location and string.format("%d ", self.starting_location) or ""
    self.terrain = start .. (self.overlay or id)(self.biome.terrain[self:get_height()])
  end
  return self.terrain
end

function Mod.Legacy:show()
  return self.terrain
end

function Mod.Legacy:set_label(text, colour)
  self.__label = { text = text, colour = colour }
end

function Mod.Legacy:label()
  if self.__label then
    return wml.merge(self.__label, self:coords())
  end
end

function Mod.Legacy:has_feature(name)
  return self.feature and (not name or self.feature.name == name)
end

function Mod.Legacy:at_night()
  local schedule = wesnoth.schedule.get_time_of_day(self)
  return schedule.lawful_bonus < 0
end

function Mod.Legacy:has_forest()
  return self.overlay and self.overlay.name == "forest"
end

function Mod.Legacy:has_village()
  return self.overlay and self.overlay.name == "village"
end

function Mod.Legacy:is_water()
  local t = self.biome.terrain[self:get_height()]
  return string.find(t, "^W") or string.find(t, "^Ss")
end

function Mod.Legacy:is_keep()
  return self.overlay and self.overlay.name == "keep"
end

function Mod.Legacy:is_castle()
  return self.overlay and self.overlay.name == "castle"
end

function Mod.Legacy:translate(v)
  local h = Mod.Base.translate(self, v)
  return self.map:get(h.x, h.y)
end

function Mod.Legacy:border_distance()
  return Mod.Base.border_distance(self, self.map)
end

function Mod.Legacy:circle(r)
  return filter_map(function(h) return self.map:get(h.x, h.y) end, Mod.Base.circle(self, r))
end

Mod.Set = {}

function Mod.Set:new(hexes, state, ctrl)
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

function Mod.Set:singleton(hex)
  local set = self:new()
  set:add(hex)
  return set
end

function Mod.Set:add(hex)
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

function Mod.Set:remove(...)
  local hex = wesnoth.map.read_location(...)
  if self[hex.y] then
    local h = self[hex.y][hex.x]
    if h then self.size = self.size - 1 end
    self[hex.y][hex.x] = nil
    return h
  end
end

function Mod.Set:random()
  if self.size < 1 then
    error("Cannot pick from an empty hex-set!")
  end
  local it = drop(mathx.random(0, self.size - 1), self:iter())
  return it()
end

function Mod.Set:pop_random()
  local h = self:random()
  self:remove(h)
  return h
end

function Mod.Set:get(x, y)
  local loc = wesnoth.map.read_location(x, y)
  if self[loc.y] then
    return self[loc.y][loc.x]
  end
end

function Mod.Set:member(x, y)
  return self:get(x, y) and true or false
end

function Mod.Set:as_area()
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

function Mod.Set:member_pred()
  return Predicate:func(function(x) return self:member(x) end)
end

function Mod.Set:iter_rows()
  local y = self.min_row - 1
  return function()
    repeat y = y + 1
    until y >= self.max_row or self[y]
    return self[y]
  end
end

function Mod.Set:iter()
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

function Mod.Set:empty()
  return self.size == 0
end

function Mod.Set:filter(predicate)
  return Mod.Set:new(filter(predicate, self:iter()))
end

function Mod.Set:intersect(other)
  local sets = { self, other }
  table.sort(sets, function(a, b) return a.size < b.size end)
  return Mod.Set:new(filter(function(h) return sets[2]:member(h) end, sets[1]:iter()))
end

function Mod.Set:diff(other)
  return self:filter(function(h) return not other:member(h) end)
end

function Mod.Set:union(other)
  return Mod.Set:new(chain(self:iter(), other:iter()))
end

function Mod.Set:partition(f)
  local results = {}
  for hex in self:iter() do
    local key = f(hex)
    if not results[key] then
      results[key] = Mod.Set:new()
    end
    results[key]:add(hex)
  end
  return results
end

function Mod.Set:wml(tag)
  local contents = {}
  for hex in self:iter() do
    table.insert(contents, wml.tag[tag or "hex"](hex))
  end
  return contents
end

function Mod.Set:from_wml(spec)
  local hset = self:new()
  for tag in iter(spec) do
    hset:add(tag[2])
  end
  return hset
end

Mod.Legacy.Set = Mod.Set

return Mod
