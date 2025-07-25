local Hex = require("scenario_toolbox/lua/map/hex")

local Biome = {}
Biome.__index = Biome

function Biome:new(name, total_feat_weight)
  local this = {
      name = name,
      heights = { },
      hexes = Hex.Set:new(),
      features = self.FeatureSet:new(total_feat_weight),
      spawn = { active = { }, passive = { } },
  }
  return setmetatable(this, self)
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
  hex.terrain = self:terrain(hex)
  self.hexes:add(hex)
end

function Biome:remove_hex(hex)
  self.hexes:remove(hex)
end

function Biome:time_area(timedef)
  local area = { id = self.name, x = "", y = "" }
  for hex in self.hexes:iter() do
    area.x = string.format("%s%i,", area.x, hex.x)
    area.y = string.format("%s%i,", area.y, hex.y)
  end
  for time in timedef do
    area = wml.merge(area, { wml.tag.time(time) }, "append")
  end
  return "time_area", area
end

function Biome:add_feat(feat)
  self.features:add(feat)
end

Biome.Feature = {}
Biome.Feature.__index = Biome.Feature

function Biome.Feature:assign(hex)
  hex.feature = self
end

function Biome.Feature:apply(hex, scenario)
  local wml = {
      x = hex.x,
      y = hex.y,
      name = "altar-" .. hex.biome.name,
      image = "items/altar-evil.png",
      visible_in_fog = true,
  }
  scenario:insert("item", wml)
  hex.biome.altar = hex
end

function Biome.Feature.overlay(name, weigh, terrain)
  local ov = { name = name, total = 0, weigh = weigh }

  for t in iter(terrain) do
    table.insert(ov, t)
    ov.total = ov.total + t.weight
  end

  function ov:apply(hex)
    local roll = mathx.random(0, self.total - 1)
    for t in iter(self) do
      if roll < t.weight then
        hex.terrain = hex.terrain .. "^" .. t.terrain
        return
      else
        roll = roll - t.weight
      end
    end
  end

  return setmetatable(ov, Biome.Feature)
end

function Biome.Feature.neighbourhood_overlay(name, radius, weight, terrain)
  return Biome.Feature.overlay(
    name,
    function(self, hex)
      local neighbours = filter(
        function(h) return h.feature and h.feature.name == self.name end,
        hex:in_circle(radius)
      )
      return { weight = weight(hex, count(neighbours)), feat = self }
    end,
    terrain
  )
end

function Biome.Feature.castle(keep, castle, weigh, expand, extra)
  local c = {
    name = "castle",
    keep = keep,
    castle = castle,
    expand = expand,
    weigh = weigh,
    extra = extra or {},
  }

  function c:apply(hex)
    local castle = self:expand(hex)
    if castle then
      hex.terrain = self.keep
      hex.feature = self
      for h in castle do
        h.terrain = self.castle
        h.feature = self
      end
    else
      hex.feature = nil
    end
  end

  return setmetatable(c, Biome.Feature)
end

function Biome.Feature.building(name, image, weigh, init)
  local b = { name = name, img = image, weigh = weigh, init = init }

  function b:apply(hex, scenario)
    scenario:insert("item", {
                      x = hex.x, y = hex.y,
                      name = self.name,
                      image = self.img,
                      visible_in_fog = true,
    })
    self:init(hex, scenario)
  end

  return setmetatable(b, Biome.Feature)
end

Biome.FeatureSet = {}
Biome.FeatureSet.__index = Biome.FeatureSet

function Biome.FeatureSet:new(total_weight)
  return setmetatable({ total_weight = total_weight or 1 }, self)
end

function Biome.FeatureSet:add(feat)
  table.insert(self, feat)
end

function Biome.FeatureSet:remove(name)
  local i = 1
  while self[i] and self[i].name ~= name do
    i = i + 1
  end
  if i <= #self then
    return table.remove(self, i)
  end
end

function Biome.FeatureSet:assign(hex)
  if hex.feature then
    return
  end
  local feats = {}
  local total = 0
  for feat in iter(self) do
    f = feat:weigh(hex)
    table.insert(feats, f)
    total = total + f.weight
  end
  -- base_weight makes it so that total should be greater than 0
  -- it also adds a chance that no feature will be selected (nil
  -- will be returned).
  local roll = mathx.random(0, mathx.max(total, self.total_weight) - 1)
  for feat in iter(feats) do
    if roll < feat.weight then
      feat.feat:assign(hex, roll)
      return feat.feat
    else
      roll = roll - feat.weight
    end
  end
end

return Biome
