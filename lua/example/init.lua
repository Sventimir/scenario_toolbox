wesnoth.require("~add-ons/scenario_toolbox/lua/lib/core.lua")
local Spawn = require("scenario_toolbox/lua/units/spawn")
local Hex = require("scenario_toolbox/lua/map/hex")
Biomes = require("scenario_toolbox/lua/example/biomes")
Item = require("scenario_toolbox/lua/item")
Inventory = require("scenario_toolbox/lua/units/inventory")
ShazzaDialogue = require("scenario_toolbox/lua/example/dialogues/shazza")

local player_sides = wesnoth.sides.find({ team_name = "Bohaterowie" })
local players_str = str.join(map(get("side"), iter(player_sides)), ",")
local enemies = wesnoth.sides.find({ wml.tag["not"]({ team_name = "Bohaterowie" }) })
local boss = wesnoth.sides.find({ team_name = "meadows" })[1]
local sites = Hex.Set:new()
meadows_terrain = "Gg,Gg^*,Hh,Hh^*,Mm,Mm^*"

micro_ai = {
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

for enemy in iter(enemies) do
  local biome = Biomes[enemy.variables.biome]
  biome.sites = {}
  for site in iter(enemy.variables.sites) do
    if biome.sites[site[1]] then
      table.insert(biome.sites[site[1]], site[2])
    else
      biome.sites[site[1]] = { site[2] }
      table.insert(biome.sites, site[1]) -- we need a way to reliably iterate over this
    end
    sites:add({ x = site[2].x, y = site[2].y, biome = biome.name, name = site[1]})
  end
  for site, hexes in pairs(biome.sites) do
    local feat = biome.features:find(site)
    if feat and feat.micro_ai then
      local mai = feat:micro_ai(hexes)
      if mai then table.insert(micro_ai, wml.tag.micro_ai(mai)) end
    end
  end
end

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

local altars = filter_map(get("sites", "altar", 1), iter(Biomes))
local sites_x, sites_y = sites:as_area()
wesnoth.game_events.add({
    name = "prestart",
    id = "setup_summons_menu",
    content = {
        wml.tag.set_menu_item({
                  id = "summon_menu",
                  description = "Przywołanie Przedwiecznego",
                  wml.tag.filter_location({
                      x = str.join(map(get("x"), altars), ","),
                      y = str.join(map(get("y"), altars), ","),
                      wml.tag["and"]({
                                wml.tag.filter_adjacent_location({
                                    wml.tag.filter({ Inventory.filter.has_item("bones") })
                                }),
                                wml.tag["or"]({
                                    wml.tag.filter({ Inventory.filter.has_item("bones") })
                                })
                      })
                  }),
        }),
        wml.tag.set_menu_item({
            id = "description_menu",
            description = "Zbadaj to miejsce",
            image = "images/misc/eye.png",
            wml.tag.filter_location({
                x = sites_x,
                y = sites_y,
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
      local speaker = wesnoth.units.find({
          side = "$side_number",
          wml.tag.filter_location({ x = x, y = y, radius = 1 })
      })[1]
      local site = sites:get(x, y)
      local feature = Biomes[site.biome].features:find(site.name)
      gui.show_narration(feature:description(speaker.portrait))
    end
)

wesnoth.game_events.add_menu(
  "summon_menu",
  function()
    local hex = Hex:from_wesnoth(wesnoth.map.get(wml.variables.x1, wml.variables.y1))
    local side = filter(
      function(s)
        local altar = wml.get_child(s.variables.sites, "altar")
        return hex:equals(altar)
      end,
      iter(enemies)
    )()
    local u = wesnoth.units.find({ Inventory.filter.has_item("bones") })[1]
    Inventory.consume(u, "bones", 1)
    local altar = wml.get_child(side.variables.sites, "altar")
    local spawn = Biomes[side.variables.biome].spawn.boss
    local x, y = wesnoth.paths.find_vacant_hex(altar.x, altar.y, { type = spawn.unit_type })
    local hex = { x = x, y = y }
    wesnoth.map.place_area({
        id = "boss-fight",
        x = altar.x,
        y = altar.y,
        radius = 3,
        wml.tag.time({
            name = "Aura Przedwiecznej Shazzy",
            description = "Wokół Przedwiecznej Istoty panuje ciemność i burza z piorunami.",
            image = "misc/time-schedules/schedule-midnight.png",
            lawful_bonus = -25,
            red = -75,
            green = -45,
            blue = -13,
        })
    })
    local avatar = spawn:spawn(hex, side.side)
    avatar[1].role = "boss"
    local u2 = wesnoth.units.find({ side = "1,2", wml.tag["not"]({ x = u.x, y = u.y}) })[1]
    local d = ShazzaDialogue(avatar, u, u2)
    d:play()
  end
)

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

wesnoth.game_events.add({
    name = string.format("side turn"),
    id = string.format("spawn"),
    first_time_only = false,
    filter = function()
      return wesnoth.sides[wml.variables.side_number].team_name ~= "Bohaterowie"
    end,
    action = function()
      -- There are 2 types of spawn: site-specific spawn at certain sites on the map
      -- and passive spawn during the night in all biomes.
      -- Note that these spawns are not mutually exclusive - they can and will
      -- happen both at night for sides that have special sites in them.
      local side = wesnoth.sides[wml.variables.side_number]
      local biome = Biomes[side.variables.biome]
      local time = wesnoth.schedule.get_time_of_day(biome.name)
      for site_type in iter(biome.sites) do -- site-specific spawn
        local f = biome.features:find(site_type)
        f:spawn(biome.sites[site_type])
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
