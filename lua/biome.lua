Biome = {}
Biome.__index = Biome

function Biome:new(name, symbol, terrain)
  return setmetatable({ name = name, symbol = symbol, _terrain = terrain }, self)  
end

function Biome:terrain(hex)
  return self._terrain
end

return Biome
