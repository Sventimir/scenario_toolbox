Biome = {}
Biome.__index = Biome

function Biome:new(name)
  return setmetatable({ name = name, hexes = {} }, self)
end

function Biome:terrain(hex)
  return self.heights[hex.height] or "_off^_usr"
end

function Biome:belongs(hex)
  return hex.biome.name == self.name
end

return Biome
