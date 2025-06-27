Biome = {}
Biome.__index = Biome

function Biome:new(name, symbol, terrain)
  return setmetatable({ name = name, symbol = symbol, _terrain = terrain }, self)  
end

function Biome:terrain(hex)
  return self.heights[hex.height] or "_off^_usr"
end

return Biome
