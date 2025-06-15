package.path = package.path .. ";/home/sven/code/wesnoth/?.lua"
require("scenario_toolbox/lua/map")
require("scenario_toolbox/lua/map")

local m = Map.new(10, 10, "G")
print(m:as_map_data())
