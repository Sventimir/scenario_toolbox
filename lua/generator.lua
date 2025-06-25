Vec = require("scenario_toolbox/lua/cubic_vector")
Hex = require("scenario_toolbox/lua/hex")
Map = require("scenario_toolbox/lua/map")
Side = require("scenario_toolbox/lua/side")
Scenario = require("scenario_toolbox/lua/scenario")

Gen = {}

local side_color = { "red", "blue", "green" }

function Gen:make(cfg)
  local s = Scenario:new(cfg:find("scenario", 1))

  for i = 1, cfg.player_count do
    local side = Side:new({
        side = i,
        color = side_color[i],
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

  self.map = Map.new(cfg.width, cfg.height, "Gg")
  s.map_data = self.map:as_map_data()
  return s
end

return Gen
