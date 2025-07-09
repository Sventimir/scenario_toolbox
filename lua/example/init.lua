wesnoth.require("~add-ons/scenario_toolbox/lua/lib/core.lua")
local Spawn = require("scenario_toolbox/lua/units/spawn")
local Hex = require("scenario_toolbox/lua/map/hex")
local WML = require("scenario_toolbox/lua/wml/wml")

require("scenario_toolbox/lua/example/biomes")

local player_sides = wesnoth.sides.find({ team_name = "Boahterowie" })
local boss = wesnoth.sides.find({ team_name = "Boss1" })[1]
boss_spawn = Spawn:new("Cave Bear")
meadows_terrain = "Gg,Gg^*,Hh,Hh^*,Mm,Mm^*"
altar = { x = boss.variables.altar_x, y = boss.variables.altar_y }

wesnoth.game_events.add({
    name = "start",
    id = "setup_micro_ai",
    content = WML:new({
        WML.micro_ai("wolves_multipacks", boss.side, {
                       type = "Wolf",
                       pack_size = 4,
                       WML:tag("avoid", {
                                 WML:tag("not", { terrain = meadows_terrain })
                       })
        }),
        WML.micro_ai("big_animals", boss.side, {
                       WML.filter({
                           type="Giant Rat",
                           WML.filter_location({
                               WML:tag("not", { area = "boss_fight" })
                           })
                       }),
                       WML.filter_location({ terrain = meadows_terrain }),
                       WML:tag("filter_location_wander", { terrain = meadows_terrain })
        }),
        WML.micro_ai("forest_animals", boss.side, {
                       tusker_type = "Woodland Boar",
                       tusklet_type = "Piglet",
                       deer_type = "Bay Horse",
                       WML:tag("filter_location", { terrain = meadows_terrain .. ",Ww" })
        }),
        WML.micro_ai("assassin", boss.side, {
                       WML.filter({ type = "Cave Bear" }),
                       WML.filter_second({ side = player_sides, canrecruit = true }),
        })
    })
})

wesnoth.game_events.add({
    name = "prestart",
    id = "setup_summons_menu",
    content = WML:new({
        WML:tag("set_menu_item", {
                  id = "summon_menu",
                  description = "Przywołanie Zbuntowanego",
                  WML.filter_location({
                      x = altar.x,
                      y = altar.y,
                      WML:tag("and", {
                                WML:tag("filter_adjacent_location", {
                                          WML.filter({ canrecruit = true })
                                }),
                                WML:tag("or", {
                                          WML.filter({ canrecruit = true })
                                })
                      })
                  }),
        })
    })
})

wesnoth.game_events.add_menu(
  "summon_menu",
  function()
    local avatar = wesnoth.units.create({
        id = "Boss1-avatar",
        name = "Imiędoustalenia",
        type = "Wose Shaman",
        side = boss.side,
        hitpoints = 100,
    })
    local x, y = wesnoth.paths.find_vacant_hex(altar.x, altar.y, avatar)
    wesnoth.map.place_area(
      WML:new({
          id = "boss-fight",
          x = altar.x,
          y = altar.y,
          radius = 3,
          WML.time({
              name = "Aura Zbuntowanego Imiędoustalenia",
              description = "Wokół Zbuntowanego panuje ciemność i burza z piorunami.",
              image = "misc/time-schedules/schedule-midnight.png",
              lawful_bonus = -25,
              red = -75,
              green = -45,
              blue = -13,
          })
      })
    )
    wesnoth.units.to_map(avatar, x, y)
end)

wesnoth.game_events.add({
    name = "die",
    id = "boss-defeated",
    first_time_only = true,
    filter = WML:new({ WML.filter({ id = "Boss1-avatar" }) }),
    content = WML:new({
        WML:tag("remove_time_area", { id = "boss-fight" }),
        WML:tag("endlevel", { result = "victory" })
    })
})

wesnoth.game_events.add({
    name = string.format("side %s turn", boss.side),
    id = string.format("%s-spawn", boss.team_name),
    first_time_only = false,
    action = function() 
      local altar = Hex:from_wesnoth(wesnoth.map.get(altar.x, altar.y))
      boss_spawn:spawn(altar, boss.side)
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
                          WML.filter(),
                          WML:tag("or", {
                                    owner_side = string.format("%i,%s", side, other_sides)
                          }),
                }),
                radius = 5,
      })
  })
end
