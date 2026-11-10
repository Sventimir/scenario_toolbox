local Hex = require("scenario_toolbox/lua/map/hex")


local Edge = { name = "map_edge" }
local __Edge = { __index  = Edge }

function Edge.new(biome, spec)
  local this = {
    biome = biome,
    width = spec.width
  }
  return setmetatable(this, __Edge)
end

Edge.Hex = setmetatable({}, Hex.__Gen)
local __Hex = { __index  = Edge.Hex }

function Edge.Hex.new(x, y)
  return setmetatable(Hex.Gen.new(x, y), __Hex)
end

function Edge.Hex:generate(_) -- luacheck: ignore 212 (unused 'self' required by interface)
  self.height = -2
  self.biome = self.prototype.biome
end

function Edge.Hex:propagate() -- luacheck: ignore 212 (unused 'self' required by interface)
  return { option = Hex.Gen, weight = 1 }
end

function Edge:place(map, frontier)
  for x in iter({ 0, map.width + 1 }) do
    for y = 0, map.height + 1 do
      local h = self.Hex.new(x, y)
      h.prototype = self
      h:generate(map)
      map:add(h)
    end
  end
  for y in iter({ 0, map.height + 1 }) do
    for x = 1, map.width do
      local h = self.Hex.new(x, y)
      h.prototype = self
      h:generate(map)
      map:add(h)
    end
  end
  for x in iter({ 1, map.width }) do
    for y = 1, map.height do
      frontier:add(Hex.Base.new(x, y))
    end
  end
  for y in iter ({ 1, map.height }) do
    for x = 2, map.height - 1 do
      frontier:add(Hex.Base.new(x, y))
    end
  end
end

return Edge
