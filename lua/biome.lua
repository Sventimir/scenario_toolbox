Biome = {}
Biome.__index = Biome

Biome.heights = {
  [-2] = "Wo",
  [-1] = "Ww",
  [0]  = "Gg",
  [1]  = "Hh",
  [2]  = "Mm",
}

function Biome:new(name, symbol, terrain)
  return setmetatable({ name = name, symbol = symbol, _terrain = terrain }, self)  
end

function Biome:terrain(hex)
  return Biome.heights[hex.height] or "_off^_usr"
end

return Biome
