WML = require("scenario_toolbox/lua/wml")

local Scenario = WML.new()

function Scenario.new(wml)
  return setmetatable(wml, Scenario)
end

return Scenario
