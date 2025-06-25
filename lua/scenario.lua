WML = require("scenario_toolbox/lua/wml")
Side = require("scenario_toolbox/lua/side")

local Scenario = WML:new()
Scenario.__index = Scenario

return Scenario
