wesnoth.require("~add-ons/scenario_toolbox/lua/lib/core.lua")
local Spawn = require("scenario_toolbox/lua/units/spawn")
local Hex = require("scenario_toolbox/lua/map/hex")
local WML = require("scenario_toolbox/lua/wml/wml")

require("scenario_toolbox/lua/example/biomes")

local player_sides = wesnoth.sides.find({ team_name = "Boahterowie" })
local boss1 = wesnoth.sides.find({ team_name = "Boss1" })[1]
boss_spawn = Spawn:new("Cave Bear")
meadows_terrain = "Gg,Gg^*,Hh,Hh^*,Mm,Mm^*"

wesnoth.game_events.add({
    name = "start",
    id = "setup_micro_ai",
    WML:tag("micro_ai", {
              side = boss1.side,
              ai_type = "wolfves_multipacks",
              action = "add",
              type = "Wolf",
              pack_size = 4, 
              WML:tag("avoid", {
                        WML:tag("not", { terrain = meadows_terrain })
              })
    }),
    WML:tag("micro_ai", {
              side = boss1.side,
              ai_type = "big_animals",
              action = "add",
              WML:tag("filter", {
                        type="Giant Rat"
              }),
              WML:tag("filter_location", { terrain = meadows_terrain }),
              WML:tag("filter_location_wander", { terrain = meadows_terrain })
    }),
    WML:tag("micro_ai", {
              side = boss1.side,
              ai_type = "forest_animals",
              action = "add",
              tusker_type = "Woodland Boar",
              tusklet_type = "Piglet",
              deer_type = "Bay Horse",
              WML:tag("filter_location", { terrain = meadows_terrain .. ",Ww" })
    }),
    WML:tag("micro_ai", {
              side = boss1.side,
              ai_type = "assasin",
              action = "add",
              WML:tag("filter", { type = "Cave Bear" }),
              WML:tag("filter_second", { side = player_sides, canrecruit = true }),
    })
})

wesnoth.game_events.add({
    name = string.format("side %s turn", boss1.side),
    id = string.format("%s-spawn", boss1.team_name),
    first_time_only = false,
    action = function() 
      local vars = boss1.variables
      local altar = Hex:from_wesnoth(wesnoth.map.get(vars.altar_x, vars.altar_y))
      boss_spawn:spawn(altar, boss1.side)
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
