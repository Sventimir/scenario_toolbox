Vec = require("scenario_toolbox/lua/cubic_vector")
Hex = require("scenario_toolbox/lua/hex")
Map = require("scenario_toolbox/lua/map")
Side = require("scenario_toolbox/lua/side")
Scenario = require("scenario_toolbox/lua/scenario")
Biome = require("scenario_toolbox/lua/biome")

GenHex = Hex:new()
GenHex.__index = GenHex

function GenHex:new(map, x, y, biome)
  return setmetatable({ map = map, x = x, y = y, biome = biome, terrain = "_off^_usr" }, self)
end

function GenHex:show()
  return self.biome.symbol
end

Map.Hex = GenHex

Gen = {
  side_color = { "red", "blue", "green" }
}

NullBiome = Biome:new("none", "x", "_off^_usr")
Meadows = Biome:new("meadows", "[38;5;34mM[0m", "Gg")
Water = Biome:new("water", "[38;5;92mW[0m", "Wo")

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
  self.center.biome = Meadows
  for hex in self.center:circle(1) do
    hex.biome = Meadows
  end
  for x = 0, cfg.width + 1 do
    self.map:get(x, 0).biome = Water
    self.map:get(x, cfg.height + 1).biome = Water
  end
  for y = 0, cfg.width + 1 do
    self.map:get(0, y).biome = Water
    self.map:get(cfg.width + 1, y).biome = Water
  end

  for hex in self.map:iter() do
    hex.terrain = hex.biome:terrain(hex)
  end

  s.map_data = self.map:as_map_data()
  return s
end

return Gen
