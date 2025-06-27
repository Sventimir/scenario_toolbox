Vec = require("scenario_toolbox/lua/cubic_vector")
CartVec = require("scenario_toolbox/lua/carthesian_vector")
Hex = require("scenario_toolbox/lua/hex")
Map = require("scenario_toolbox/lua/map")
Side = require("scenario_toolbox/lua/side")
Scenario = require("scenario_toolbox/lua/scenario")
Biome = require("scenario_toolbox/lua/biome")

GenHex = Hex:new()
GenHex.__index = GenHex

function GenHex:new(map, x, y, biome)
  return setmetatable({
      map = map,
      x = x,
      y = y,
      biome = biome,
      height = nil,
      terrain = "_off^_usr"
  }, self)
end

function GenHex:show_biome()
  return self.biome.symbol
end

function GenHex:show_height()
  if not self.height then
    return "x"
  elseif self.height >= 0 then
    return string.format("[38;5;2m%i[0m", self.height)
  else
    return string.format("[38;5;1m%i[0m", - self.height)
  end
end

function GenHex:show_coord()
  if self.x == self.y then
    return self.x % 10
  else
    return " "
  end
end

GenHex.show = GenHex.show_height

Map.Hex = GenHex

Gen = {
  side_color = { "red", "blue", "green" }
}

NullBiome = Biome:new("none", "x", "_off^_usr")
NullBiome._nil = true
Meadows = Biome:new("meadows", "[38;5;34mM[0m", "Gg")

local function hex_height(hex)
  if hex then return hex.height else return nil end
end

function Gen:paint_circle(center, radius, biome, overwrite)
  for d = 1, radius do
    for hex in center:circle(d) do
      if hex.biome._nil or overwrite then
        hex.biome = biome
      end
    end
  end
end

function Gen:border_height(hex)
  hex.height = - mathx.random(1, 2)
end

function Gen:fjord_height(hex)
  local mean = arith.round(arith.mean(filter_map(hex_height, hex:circle(1))))
  local h = mean + mathx.random(-1, 1)
  if h >= 0 and mean <= 0 then
    h = h + mathx.random(0, 1)
  end
  hex.height = mathx.max(-2, mathx.min(2, h))
end

function Gen:interior_height(hex)
  local mean = arith.round(arith.mean(filter_map(hex_height, hex:circle(1))))
  local d = arith.round(mathx.random(-2, 2) / 2)
  if d > 0 then
    d = d + mathx.random(0, 1)
  end
  hex.height = mathx.max(-2, mathx.min(2, mean + d))
end

function Gen:height_map()
  local x = 0
  local y = 0
  local next_movement = cycle({ CartVec.east, CartVec.south, CartVec.west, CartVec.north })
  local v = next_movement()
  local hex = self.map:get(x, y)
  local set_height = self.border_height

  while not hex.height do
    set_height(self, hex)
    x, y = v:translate(x, y)
    hex = self.map:get(x, y)
    if not hex or hex.height then
      local next_v = next_movement()
      x, y = (next_v - v):translate(x, y)
      hex = self.map:get(x, y)
      v = next_v
    end
    if x == 3 and y == 3 then
      set_height = self.fjord_height
    elseif x == 9 and y == 9 then
      set_height = self.interior_height
    end
  end

  self.center = hex
  self.center.height = 0
end

function Gen:make(cfg)
  local s = Scenario:new(cfg:find("scenario", 1))

  for i = 1, cfg.player_count do
    local side = Side:new({
        side = i,
        color = self.side_color[i],
        faction = "Custom",
        faction_lock = true,
        leader_lock = false,
        fog = true,
        shroud = true,
        gold = 0,
        hidden = false,
        income = 0,
        save_id = "player" .. i,
        team_name = "Bohaterowie",
        team_user_name = "Bohaterowie",
        defeat_condition = "never",
    })
    s:insert("side", side)
  end
  s:insert("side", Side:new({
               side = cfg.player_count + 1,
               color = "black",
               faction = "Custom",
               controller = "ai",
               faction_lock = true,
               leader_lock = false,
               fog = false,
               shroud = false,
               gold = 0,
               hidden = true,
               income = 0,
               team_name = "Boss1",
               team_user_name = "Boss1",
               defeat_condition = "never",
  }))

  self.map = Map:new(cfg.width, cfg.height, NullBiome)

  self.center = self.map:get(cfg.width / 2, cfg.height / 2)
  
  self:height_map()

  self.center.biome = Meadows
  self:paint_circle(self.center, 3, Meadows)
  
  local potential_boss_locations = as_table(self.center:circle(cfg.width / 2 - 1))
  self.boss_loc = potential_boss_locations[mathx.random(#potential_boss_locations)]
  self.boss_loc.biome = Meadows
  self:paint_circle(self.boss_loc, 3, Meadows)

  for hex in self.map:iter() do
    hex.terrain = hex.biome:terrain(hex)
  end

  s.map_data = self.map:as_map_data()
  return s
end

return Gen
