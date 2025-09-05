wesnoth.require("~add-ons/scenario_toolbox/lua/lib/core.lua")
Dialogue = require("scenario_toolbox/lua/events/dialogue")
Spawn = require("scenario_toolbox/lua/units/spawn")
Hex = require("scenario_toolbox/lua/map/hex")
Item = require("scenario_toolbox/lua/item")
Inventory = require("scenario_toolbox/lua/units/inventory")

local player_sides = wesnoth.sides.find({ team_name = "Bohaterowie" })
local players_str = str.join(map(get("side"), iter(player_sides)), ",")
local meadows = wesnoth.sides.find({ team_name = "meadows" })[1]
meadows_terrain = "Gg,Gg^*,Hh,Hh^*,Mm,Mm^*"

micro_ai = {
  wml.tag.micro_ai({
      ai_type = "big_animals",
      side = meadows.side,
      action = "add",
      wml.tag.filter({
          type="Giant Rat",
          wml.tag.filter_location({
              wml.tag["not"]({ area = "meadows-fight" })
          })
      }),
      wml.tag.filter_location({ terrain = meadows_terrain }),
      wml.tag.filter_location_wander({ area = "meadows" })
  }),
  wml.tag.micro_ai({
      ai_type ="forest_animals",
      side = meadows.side,
      action = "add",
      tusker_type = "Woodland Boar",
      tusklet_type = "Piglet",
      deer_type = "Bay Horse,Raven",
      wml.tag.filter_location({ area = "meadows" })
  }),
  wml.tag.micro_ai({
      ai_type = "assassin",
      side = meadows.side,
      action = "add",
      wml.tag.filter({ type = "Wolf" }),
      wml.tag.filter_second({
          side = players_str,
          canrecruit = true
      }),
  })
}

local objectives = {
  wml.tag.objectives({
      team_name = "Bohaterowie",
      summary = "Odnajdź i pokonaj Przedwieczną Shazzę.",
      wml.tag.objective({
          condition = "win",
          description = "Odnajdź ołtarz przywołania Przedwiecznej.",
      }),
      wml.tag.objective({
          condition = "win",
          description = "Zdobądź ofiarę konieczną do przywołania.",
      }),
      wml.tag.objective({
          condition = "win",
          description = "Pokonaj Przedwieczną.",
      }),
      wml.tag.note({
          description = "Ołtarz znajduje się gdzieś na łąkach wyspy.",
      }),
      wml.tag.note({
          description = "Wskazówkę co do wymaganej ofiary można znaleźć przy ołtarzu przedwiecznego.",
      }),
      wml.tag.note({
          description = "Specjalne lokacje zawierają opisy. Podejdź do nich dowoną jednostką i kliknij prawym przyciskiem aby się im przyjrzeć."
      }),
  })
}

wesnoth.game_events.add({
    name = "start",
    id = "setup_micro_ai",
    content = wml.merge(micro_ai, objectives)
})

wesnoth.game_events.add({
    name = "prestart",
    id = "setup_summons_menu",
    content = {
        wml.tag.set_menu_item({
            id = "description_menu",
            description = "Zbadaj to miejsce",
            image = "images/misc/eye.png",
            wml.tag.filter_location({
                find_in="sites",
                wml.tag["and"]({
                    wml.tag.filter_adjacent_location({
                        wml.tag.filter({ side = "$side_number" })
                    }),
                    wml.tag["or"]({
                        wml.tag.filter({ side = "$side_number" })
                    })
                }),
            })
        })
    }
})

wesnoth.game_events.add_menu(
    "description_menu",
    function()
      local x = wml.variables.x1
      local y = wml.variables.y1
      local item = wesnoth.interface.get_items(x, y)[1]
      local speaker = wesnoth.units.find({
          side = "$side_number",
          wml.tag.filter_location({ x = x, y = y, radius = 1 })
      })[1]
      gui.show_narration({
          portrait = speaker.portrait,
          title = item.variables.title,
          message = item.variables.description,
      })
    end
)

wesnoth.game_events.add({
    name = "attacker hits",
    id = "enemy-hit",
    first_time_only = false,
    filter = {
      wml.tag.filter({ side = players_str })
    },
    action = function(...)
      -- Clear any micro AIs affecting the hit unit.
      wml.variables.second_unit.role = ""
    end
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
    name = "die",
    id = "skeleton-defeated",
    first_time_only = false,
    filter = {
      unit = { type = [[ Skeleton,Skeleton Archer,Skeleton Rider,Skeletal Dragon,
                         Revenant,Lich,Draug,Deathblade,Death Squire,Death Knight,
                         Chocobone,Bone Shooter,Bone Knight,Banebow,Ancient Lich ]] },
      second_unit = { side = players_str },
    },
    action = function()
      Item.bones:drop(wml.variables.unit)
    end
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

function nightly_respawn(spec)
  local spawns = {}
  for s in wml.child_range(spec, "spawn") do
    table.insert(spawns, Spawn:from_spec(wml.literal(s)))
  end
  if #spawns == 0 then return end 
  local hexes = wesnoth.map.find({
      time_of_day = "chaotic",
      area = spec.area,
      owner_side = "0," .. spec.side,
      wml.tag.filter_vision({ visible = false, side = players_str }),
      wml.tag["not"]({
          wml.tag.filter({}),
          wml.tag["or"]({ owner_side = players_str }),
          radius = 5,
      })
  })
  local hexset = Hex.Set:new(iter(hexes))
  while hexset.size > 0 do
    local s = spawns[mathx.random(#spawns)]
    local hex = Hex:from_wesnoth(hexset:random())
    hexset = hexset:diff(Hex.Set:new(hex:in_circle(5)))
    s:spawn(hex, spec.side)
  end
end
