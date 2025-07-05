wesnoth.require("~add-ons/scenario_toolbox/lua/lib/core.lua")
local Spawn = require("scenario_toolbox/lua/units/spawn")
local Hex = require("scenario_toolbox/lua/map/hex")
local WML = require("scenario_toolbox/lua/wml/wml")

require("scenario_toolbox/lua/example/biomes")

local boss1 = wesnoth.sides.find({ team_name = "Boss1" })[1]

wesnoth.game_events.add({
    name = "prestart",
    id = "initial-spawn",
    action = function()
      local spawns = {
        Spawn:wolf_pack("Wolf", 2, 4),
        Spawn:family("Woodland Boar", "Piglet", 2, 4),
        Spawn:new("Giant Rat"),
        Spawn:new("Bay Horse"),
      }
      local available_hexes = wesnoth.map.find(inactive_spawn_filter(Meadows, boss1.side))
      while #available_hexes > 0 do
        local hex = available_hexes[mathx.random(#available_hexes)]
        spawns[mathx.random(#spawns)]:spawn(hex, boss1.side)
      end
    end
})

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

function inactive_spawn_filter(biome, side)
  local other_sides = fold(
    function(acc, s)
      if acc == "" then
        return tostring(s.side)
      else
        return string.format("%s,%i", acc, s.side)
      end
    end,
    "",
    iter(wesnoth.sides.find({ WML:tag("not", { side = side }) }))
  )
  return WML:new({
      area = biome.name,
      WML:tag("filter_vision", {
                visible = false,
                respect_fog = true,
                side = other_sides,
      }),
      WML:tag("not", {
                WML:tag("and", {
                          WML:tag("filter", {}),
                          WML:tag("or", {
                                    owner_side = string.format("%i,%s", side, other_sides)
                          }),
                }),
                radius = 5,
      })
  })
end
