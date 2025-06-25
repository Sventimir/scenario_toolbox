package.path = package.path .. ";/home/sven/code/wesnoth/?.lua"
require("scenario_toolbox/lua/core")
Gen = require("scenario_toolbox/lua/generator")

local m = Gen:make(30, 30)
display_table(m)
