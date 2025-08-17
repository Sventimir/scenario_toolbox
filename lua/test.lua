package.path = package.path .. ";/home/sven/code/wesnoth/?.lua"
require("scenario_toolbox/lua/lib/core")
Prob = require("scenario_toolbox/lua/lib/probability")

p = Prob.Normal:new(2, 0.25)
