package.path = package.path .. ";/home/sven/code/wesnoth/?.lua"
require("scenario_toolbox/lua/lib/core")
Hex = require("scenario_toolbox/lua/map/hex")

s = Hex.Set:new(iter({
                { x = 2, y = 4, z = 3 },
                { x = 3, y = 7, z = 32 },
                { x = 2, y = 3, z = 2 }
}))
