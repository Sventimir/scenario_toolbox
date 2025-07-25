wesnoth.require("~add-ons/scenario_toolbox/lua/lib/core.lua")
local Spawn = require("scenario_toolbox/lua/units/spawn")
local Hex = require("scenario_toolbox/lua/map/hex")
Biomes = require("scenario_toolbox/lua/example/biomes")

local player_sides = wesnoth.sides.find({ team_name = "Bohaterowie" })
local players_str = str.join(map(get("side"), iter(player_sides)), ",")
local enemies = wesnoth.sides.find({ wml.tag["not"]({ team_name = "Bohaterowie" }) })
local boss = wesnoth.sides.find({ team_name = "meadows" })[1]
meadows_terrain = "Gg,Gg^*,Hh,Hh^*,Mm,Mm^*"

for enemy in iter(enemies) do
  if enemy.variables.altar then
    local loc = enemy.variables.altar
    Biomes[enemy.variables.biome].altar = Hex:from_wesnoth(
      wesnoth.map.get(loc.x, loc.y)
    )
  end
end

wesnoth.game_events.add({
    name = "start",
    id = "setup_micro_ai",
    content = {
        wml.tag.micro_ai({
            ai_type = "swarm",
            side = boss.side,
            action = "add",
            wml.tag.filter({ type = "Raven" }),
            wml.tag.avoid({
                wml.tag.filter_location({
                    wml.tag["not"]({ area = "meadows" })
                })
            }),
            enemy_distance = 3,
        }),
        wml.tag.micro_ai({
          ai_type = "big_animals",
          side = boss.side,
          action = "add",
          wml.tag.filter({
              type="Giant Rat",
              wml.tag.filter_location({
                  wml.tag["not"]({ area = "boss-fight" })
              })
          }),
          wml.tag.filter_location({ terrain = meadows_terrain }),
          wml.tag.filter_location_wander({ area = "meadows" })
        }),
        wml.tag.micro_ai({
            ai_type ="forest_animals",
            side = boss.side,
            action = "add",
            tusker_type = "Woodland Boar",
            tusklet_type = "Piglet",
            deer_type = "Bay Horse",
            wml.tag.filter_location({ terrain = meadows_terrain .. ",Ww" })
        }),
        wml.tag.micro_ai({
          ai_type = "assassin",
          side = boss.side,
          action = "add",
          wml.tag.filter({ type = "Wolf" }),
          wml.tag.filter_second({
              side = players_str,
              canrecruit = true
          }),
        })
    }
})

local altars = filter_map(get("altar"), iter(Biomes))
wesnoth.game_events.add({
    name = "prestart",
    id = "setup_summons_menu",
    content = {
        wml.tag.set_menu_item({
                  id = "summon_menu",
                  description = "Przywołanie Zbuntowanego",
                  wml.tag.filter_location({
                      x = str.join(map(get("x"), altars), ","),
                      y = str.join(map(get("y"), altars), ","),
                      wml.tag["and"]({
                                wml.tag.filter_adjacent_location({
                                    wml.tag.filter({ canrecruit = true })
                                }),
                                wml.tag["or"]({
                                    wml.tag.filter({ canrecruit = true })
                                })
                      })
                  }),
        })
    }
})

wesnoth.game_events.add_menu(
  "summon_menu",
  function()
    local altar = Hex:from_wesnoth(wesnoth.map.get(wml.variables.x1, wml.variables.y1))
    local side = filter(
      function(s)
        return s.variables.altar.x == altar.x and s.variables.altar.y == altar.y
      end,
      iter(enemies)
    )()
    local spawn = Biomes[side.variables.biome].spawn.boss
    local x, y = wesnoth.paths.find_vacant_hex(altar.x, altar.y, { type = spawn.unit_type })
    local hex = { x = x, y = y }
    wesnoth.map.place_area({
        id = "boss-fight",
        x = altar.x,
        y = altar.y,
        radius = 3,
        wml.tag.time({
            name = "Aura Zbuntowanego Imiędoustalenia",
            description = "Wokół Zbuntowanego panuje ciemność i burza z piorunami.",
            image = "misc/time-schedules/schedule-midnight.png",
            lawful_bonus = -25,
            red = -75,
            green = -45,
            blue = -13,
        })
    })
    local avatar = spawn:spawn(hex, side.side)
    avatar[1].role = "boss"
end)

wesnoth.game_events.add({
    name = "die",
    id = "boss-defeated",
    first_time_only = false,
    filter = { wml.tag.filter({ role = "boss" }) },
    content = {
        wml.tag.remove_time_area({ id = "boss-fight" }),
        wml.tag.endlevel({ result = "victory" })
    }
})

wesnoth.game_events.add({
    name = "die",
    id = "hero-defeated",
    first_time_only = false,
    filter = { 
      wml.tag.filter({
          canrecruit = true,
          side = players_str,
    })},
    action = function()
      local u = wml.variables.unit
      wesnoth.sides[u.side].variables.dead_leader = wml.variables.unit
    end,
})

wesnoth.game_events.add({
    name = "side turn",
    id = "player-turn-start",
    first_time_only = false,
    filter = { wml.tag.filter_side({ side = players_str }) },
    action = function()
      local side = wesnoth.sides[wesnoth.current.side]
      if side.variables.dead_leader then
        local anim = wesnoth.units.create_animator()
        local u = wesnoth.units.create(side.variables.dead_leader)
        u.x = side.starting_location.x
        u.y = side.starting_location.y
        u.hitpoints = mathx.min(10, u.max_hitpoints)
        u.experience = u.experience / 2
        anim:add(u, "levelin", "")
        wesnoth.units.to_map(u)
        anim:run()
        side.variables.dead_leader = nil
      end
    end,
})

wesnoth.game_events.add({
    name = string.format("side turn"),
    id = string.format("spawn"),
    first_time_only = false,
    filter = function()
      return wesnoth.sides[wml.variables.side_number].team_name ~= "Bohaterowie"
    end,
    action = function()
      -- There are 2 types of spawn: active spawn every turn at the altar
      -- and passive spawn during the night in all biomes.
      -- Note that these spawns are not mutually exclusive - they can and will
      -- happen both for the active side during the night.
      local side = wesnoth.sides[wml.variables.side_number]
      local biome = Biomes[side.variables.biome]
      local time = wesnoth.schedule.get_time_of_day(biome.name)
      if wml.variables.active == biome.name then -- active spawn
        local spawn = biome.spawn.active[mathx.random(#biome.spawn.active)]
        local altar = Hex:from_wesnoth(wesnoth.map.get(side.variables.altar.x, side.variables.altar.y))
        spawn:spawn(altar, side.side)
      end
      if time.lawful_bonus < 0 and #biome.spawn.passive > 0 then -- passive spawn
        local filt = inactive_spawn_filter(biome.name, side.side)
        local hexes = Hex.Set:new(iter(wesnoth.map.find(filt)))
        while hexes.size > 0 do
          local h = Hex:from_wesnoth(hexes:random())
          local s = biome.spawn.passive[mathx.random(#biome.spawn.passive)]
          s:spawn(h, side.side)
          hexes = Hex.Set:new(iter(wesnoth.map.find(filt)))
        end
      end
    end
})

function inactive_spawn_filter(area, side)
  local other_sides = fold(
    function(acc, s)
      if acc == "" then
        return tostring(s.side)
      else
        return string.format("%s,%i", acc, s.side)
      end
    end,
    "",
    iter(wesnoth.sides.find({ wml.tag["not"]({ side = side }) }))
  )
  return {
      area = area,
      wml.tag.filter_vision({
          visible = false,
          respect_fog = true,
          side = other_sides,
      }),
      wml.tag["not"]({
          wml.tag["and"]({
              wml.tag.filter({}),
              wml.tag["or"]({
                  owner_side = string.format("%i,%s", side, other_sides)
              }),
          }),
          radius = 5,
      })
  }
end
