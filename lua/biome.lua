local Hex = require("scenario_toolbox/lua/hex")

local Biome = {}
Biome.__index = Biome

function Biome:new(name)
  return setmetatable({ name = name, hexes = Hex.Set:new(), features = {} }, self)
end

function Biome:terrain(hex)
  local base = self.heights[hex.height] or "_off^_usr"
  local overlay = hex.feature
    and "^" .. hex.feature.overlays[mathx.random(#hex.feature.overlays)]
    or ""
  return string.format("%s%s", base, overlay)
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

function Biome:add_feat(name, probability, overlays, modifier)
  table.insert(self.features, self.Feature:new(name, probability, overlays, modifier))
end

function Biome:apply_features(hex)
  for feat in iter(self.features) do
    if feat:apply(hex) then return true end
  end
  return false
end

Biome.Feature = {}
Biome.Feature.__index = Biome.Feature

function Biome.Feature:new(name, probability, overlays, modifier)
  local feat = {
    name = name,
    probability = probability,
    overlays = overlays,
    modifier = modifier
  }
  setmetatable(feat, self)
  return feat
end

function Biome.Feature:apply(hex)
  local chance = self.modifier(self.probability, hex)
  if chance:prob_check() then
    hex.feature = self
    return true
  else
    return false
  end
end

return Biome
