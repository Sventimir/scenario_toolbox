wesnoth.require("~add-ons/scenario_toolbox/lua/lib/core.lua")
local Spawn = require("scenario_toolbox/lua/units/spawn")
local Hex = require("scenario_toolbox/lua/map/hex")

local boss1 = wesnoth.sides.find({ team_name = "Boss1" })[1]

wesnoth.game_events.add({
    name = string.format("side %s turn", boss1.side),
    id = string.format("%s-spawn", boss1.team_name),
    first_time_only = false,
    action = function() 
      local vars = boss1.variables
      local altar = Hex:from_wesnoth(wesnoth.map.get(vars.altar_x, vars.altar_y))
      Spawn:wolf_pack("Wolf", 3, 6):spawn(altar, boss1.side)
    end
})
