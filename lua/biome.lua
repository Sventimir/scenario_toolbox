local Hex = require("scenario_toolbox/lua/hex")

local Biome = {}
Biome.__index = Biome

function Biome:new(name)
  return setmetatable({ name = name, hexes = Hex.Set:new() }, self)
end

function Biome:terrain(hex)
  return self.heights[hex.height] or "_off^_usr"
end

function Biome:belongs(hex)
  return hex.biome and hex.biome.name == self.name
end

function Biome:add_hex(hex)
  if hex.biome then
    hex.biome:remove_hex(hex)
  end
  hex.biome = self
  self.hexes:add(hex)
end

function Biome:remove_hex(hex)
  self.hexes:remove(hex)
end

function Biome:time_area(timedef)
  local area = WML:new({ id = self.name, x = "", y = "" })
  for hex in self.hexes:iter() do
    area.x = string.format("%s%i,", area.x, hex.x)
    area.y = string.format("%s%i,", area.y, hex.y)
  end
  for time in timedef do
    area:insert("time", time)
  end
  return "time_area", area
end

return Biome
