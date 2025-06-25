Vec = require("scenario_toolbox/lua/cubic_vector")
Hex = require("scenario_toolbox/lua/hex")
Map = require("scenario_toolbox/lua/map")
Scenario = require("scenario_toolbox/lua/scenario")

Gen = {}

function Gen:make(cfg)
  local s = Scenario.new(cfg.scenario)
  self.map = Map.new(cfg.width, cfg.height, "G")
  s.map_data = self.map:as_map_data()
  return s
end

return Gen
