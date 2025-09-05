Hex = require("scenario_toolbox/lua/map/hex")
Inventory = require("scenario_toolbox/lua/units/inventory")
Prob = require("scenario_toolbox/lua/lib/probability")
Spawn = require("scenario_toolbox/lua/units/spawn")

local Site = {}
Site.Map = {}

function Site:new()
  return setmetatable({ variables = {} }, { __index = self })
end

function Site:sample_distance(spec)
  return spec.prob:sample_int(spec.minimum, spec.maximum)
end

function Site:wml(x, y)
  local spec = {
    name = self.name,
    image = self.image,
    visible_in_fog = true,
    wml.tag.variables(self.variables),
  }
  return { wml.tag.item(wml.merge(spec, wesnoth.map.read_location(x, y), "append")) }
end

Site.origin = { name = "origin", image = "items/altar.png" }
setmetatable(Site.origin, { __index = Site })

function Site.origin:new()
  local s = Site.new(self, "origin", "items/altar.png")
  s.variables.title = "Ołtarz Baziola"
  s.variables.description = "Na tym ołtarzu Praojciec Baziol przyjmuje ofiary z pokonanych przedwiecznych. "
    .. "Obecnie naszym celem jest Shazza, której szukać należy na łąkach."
  return s
end

function Site.origin:wml(x, y)
  local location = wesnoth.map.read_location(x, y)
  local spec = Site.wml(self, location)
  local dialogue = {
    name = "start",
    wml.tag.dialogue({
      filename = "scenario_toolbox/lua/example/dialogues/opening",
      x = location.x,
      y = location.y,
    })
  }
  table.insert(spec, wml.tag.event(dialogue))
  return spec
end

Site.altar = {
  name = "altar",
  image = "items/altar-evil.png",
}
setmetatable(Site.altar, { __index = Site })

function Site.altar:new(spec, biome)
  local alt = Site.new(self)
  alt.biome = biome
  alt.variables.title = "Ołtarz Przedwiecznego"
  alt.variables.description = spec.description

  local dist = wml.get_child(spec, "distance_from_origin")
  alt.distance = Prob.Normal:new(dist.mean, dist.standard_deviation)
  alt.min_dist = dist.minimum or 1
  alt.max_dist = dist.maximum or mathx.huge
  alt.spawn = wml.get_child(spec, "spawn")
  alt.boss = wml.get_child(spec, "boss")
  alt.boss_id = string.format("%s-boss", alt.biome.name)
  return alt
end

function Site.altar:wml(x, y)
  local spec = Site.wml(self, x, y)
  local location = wesnoth.map.read_location(x, y)
  local neighbourhood = wml.clone(location)
  neighbourhood.radius = 1
  if self.spawn then
    local spawn_event = {
      name = string.format("side %i turn", self.biome.side.side),
      first_time_only = false,
      id = string.format("%s-altar-spawn", self.biome.name),
    }
    local filter = {
        wml.tag.variable({
            name = "active",
            equals = self.biome.name,
        }),
    }
    if self.boss then
      local absent_boss = { wml.tag.have_unit({ id = self.boss_id }) }
      table.insert(filter, wml.tag["not"](absent_boss))
    end
    local spawn = wml.merge(wml.clone(self.spawn), location, "append")
    spawn.side = self.biome.side.side
    table.insert(spawn_event, wml.tag.filter_condition(filter))
    table.insert(spawn_event, wml.tag.spawn(spawn))
    table.insert(spec, wml.tag.event(spawn_event))
  end
  if self.boss then
    local unit_filter = { side = "$side_number" }
    local requirement = wml.get_child(self.boss, "requirement")
    if requirement then
      unit_filter.formula = Inventory.formula.has_item(
        requirement.item,
        requirement.quantity
      )
    end
    local boss_menu = {
      id = string.format("%s-summon-menu", self.biome.name),
      description = "Przywołanie Przedwiecznego",
    }
    local filter = {
      x = location.x, y = location.y,
      wml.tag["and"]({
          wml.tag.filter_adjacent_location({ wml.tag.filter(unit_filter) }),
          wml.tag["or"]({ wml.tag.filter(unit_filter) })
      }),
    }
    table.insert(boss_menu, wml.tag.filter_location(filter))
    local unit = wml.clone(self.boss)
    wml.remove_child(unit, "requirement")
    local spawn = wml.merge({ wml.tag.unit(unit) }, location, "append")
    local time_area_id = string.format("%s-boss-fight", self.biome.name)
    local boss_defeat_id = string.format("%s-boss-defeated", self.biome.name)
    spawn.side = self.biome.side.side
    local cmd = {
      wml.tag.store_unit({
          variable = "summoner",
          wml.tag.filter(unit_filter),
      }),
      wml.tag.inventory({
          wml.tag.filter(unit_filter),
          action = "remove",
          item = "bones",
          quantity = 1,
      }),
      wml.tag.time_area({
          id = time_area_id,
          x = "$x1", y = "$y1", radius = 3,
          wml.tag.time({
              name = "Aura Przedwiecznego",
              description = "Wokół Przedwiecznej Istoty panuje ciemność i burza z piorunami.",
              image = "misc/time-schedules/schedule-midnight.png",
              lawful_bonus = -25,
              red = -75,
              green = -45,
              blue = -13,
          })
      }),
      wml.tag.spawn(spawn),
      wml.tag.event({
          name = "die",
          id = boss_defeat_id,
          first_time_only = false,
          wml.tag.filter({ id = unit.id }),
          wml.tag.remove_time_area({ id = time_area_id }),
          wml.tag.endlevel({ result = "victory" }),
          wml.tag.event({ id = boss_defeat_id, remove = true }),
      })
    }
    if self.biome.name == "meadows" then
      local d = {
        filename = "scenario_toolbox/lua/example/dialogues/shazza",
        player_sides = cfg.player_sides
      }
      table.insert(cmd, wml.tag.dialogue(d))
    end
    table.insert(cmd, wml.tag.clear_variable({ name = "summoner" }))
    table.insert(boss_menu, wml.tag.command(cmd))
    local prestart = {
      name = "prestart",
      wml.tag.set_menu_item(boss_menu)
    }
    table.insert(spec, wml.tag.event(prestart))
  end
  return spec
end

function Site.altar:place(origin, available_hexes)
  local r = self.distance:sample_int(self.min_dist, self.max_dist)
  local hexset = Hex.Set:new(origin:circle(r)):intersect(
    available_hexes:filter(function(h) return h.height >= 0 end)
  )
  local i = 0
  while hexset:empty() and r + i <= self.max_dist and r - i >= self.min_dist do
    i = i + 1
    hexset = Hex.Set:new(chain(origin:circle(r + i), origin:circle(r - i)))
    hexset = hexset:intersect(available_hexes)
  end
  if hexset:empty() then
    error("No valid locations for altar!")
  end
  self.altars[self.biome.name] = hexset:random()
  return iter({ self:wml(self.altars[self.biome.name]) })
end

Site.burial = {
  name = "burial",
  image = "items/burial.png",
}
setmetatable(Site.burial, { __index = Site })

function Site.burial:new(spec, biome)
  local burial = Site.new(self)
  burial.biome = biome
  burial.variables.title = "Miejsce pochówku"
  burial.variables.description = "Miejsce pochówku prawdawnego bohatera. Pewnie jest nawiedzone..."
  burial.count = spec.count
  burial.spawn = wml.child_array(spec, "spawn")
  burial.distance = {}
  for loc in iter({ "origin", "altar" }) do
    local dist = wml.get_child(spec, "distance_from_" .. loc)
    burial.distance[loc] = {
      minimum = dist.minimum,
      maximum = dist.maximum,
      prob = Prob.Normal:new(dist.mean, dist.standard_deviation),
    }
  end
  return burial
end

function Site.burial:wml(x, y)
  local spec = Site.wml(self, x, y)
  local location = wesnoth.map.read_location(x, y)
  local neighbourhood = wml.clone(location)
  neighbourhood.radius = 5

  local current_spawn = {
    wml.tag.filter({
        side = self.biomes.swamp.side.side,
        role = "burial",
    }),
    wml.tag["and"](wml.clone(neighbourhood))
  }
  local spawn_args = {
    side = self.biomes.swamp.side.side,
    wml.tag.location(neighbourhood),
  }
  for spawn in iter(self.spawn) do
    table.insert(spawn_args, wml.tag.spawn(spawn))
  end
  local lua = {
      code = [[ local Site = require("scenario_toolbox/lua/example/site_events")
                Site.burial:new():spawn(...)
             ]],
      wml.tag.args(spawn_args)
  }
  local spawn_event = {
    name = string.format("side %i turn", self.biomes["swamp"].side.side),
    id = string.format("burial-spawn-%i-%i", location.x, location.y),
    first_time_only = false,
    wml.tag.filter_condition({
        wml.tag.have_location({
            wml.tag.filter({ side = self.player_sides }),
            wml.tag["and"](neighbourhood)
        }),
        wml.tag["not"]({ wml.tag.have_location(current_spawn) }),
    }),
    wml.tag.lua(lua)
  }
  table.insert(spec, wml.tag.event(spawn_event))

  local micro_ai_setup = {
    name = "start",
    first_time_only = true,
    wml.tag.micro_ai({
        ai_type = "zone_guardian",
        side = self.biomes.swamp.side.side,
        action = "add",
        wml.tag.filter({ role = "burial" }),
        wml.tag.filter_location(neighbourhood),
    })
  }
  table.insert(spec, wml.tag.event(micro_ai_setup))

  return spec
end

function Site.burial:place(origin, available_hexes)
  local wmls = {}
  for i = 1, self.count do
    local altar_origin_dist = origin:distance(self.altars[self.biome.name])
    local dist_origin = self:sample_distance(self.distance.origin)
    local min_altar_dist = mathx.abs(altar_origin_dist - dist_origin)
    local max_altar_dist = altar_origin_dist + dist_origin
    self.distance.altar.minimum = mathx.max(self.distance.altar.minimum, min_altar_dist)
    self.distance.altar.maximum = mathx.min(self.distance.altar.maximum, max_altar_dist)
    self.distance.altar.prob.mean = arith.mean(
      iter({
          self.distance.altar.minimum,
          self.distance.altar.maximum,
      })
    )
    local dist_altar = self:sample_distance(self.distance.altar)
    local orig_circ = Hex.Set:new(origin:circle(dist_origin))
    local altar_circ = Hex.Set:new(self.altars[self.biome.name]:circle(dist_altar))
    local intersect = orig_circ:intersect(altar_circ)
    local available = available_hexes:intersect(intersect)
    local r = 0
    while available.size == 0 do
      r = r + 1
      available = Hex.Set:new(join(map(function(h) return h:circle(r) end, intersect:iter())))
      available = available:intersect(available_hexes)
    end
    table.insert(wmls, self:wml(available:random()))
  end
  return iter(wmls)
end

function Site:init(map, biomes, cfg)
  self.map = map
  self.biomes = biomes
  self.altars = {}
  self.player_sides = str.join(take(cfg.player_count, arith.nats()), ",")
end

return Site
