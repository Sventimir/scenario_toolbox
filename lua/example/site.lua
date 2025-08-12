Hex = require("scenario_toolbox/lua/map/hex")
Inventory = require("scenario_toolbox/lua/units/inventory")
Prob = require("scenario_toolbox/lua/lib/probability")
Spawn = require("scenario_toolbox/lua/units/spawn")

local Site = {}
Site.Map = {}

function Site:new()
  return setmetatable({ variables = {} }, { __index = self })
end

function Site:wml(x, y)
  local spec = {
    name = self.name,
    image = self.image,
    visible_in_fog = true,
    wml.tag.variables(self.variables),
  }
  if y then
    spec.x = x
    spec.y = y
  else
    spec.x = x.x
    spec.y = x.y
  end
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
  local lua_code = [[
    local opening_dialogue = require("scenario_toolbox/lua/example/dialogues/opening")
    local d = opening_dialogue({ x = %i, y = %i})
    d:play()
  ]]
  local dialogue = wml.tag.event({
      name = "start",
      wml.tag.lua({ code = string.format(lua_code, location.x, location.y) })      
  })
  table.insert(spec, dialogue)
  return spec
end

Site.altar = {
  name = "altar",
  image = "items/altar-evil.png",
  radius = Prob.Normal:new()
}
setmetatable(Site.altar, { __index = Site })

Site.altar.radius.lerp_strict = true

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
    local boss_menu = {
      id = string.format("%s-summon-menu", self.biome.name),
      description = "Przywołanie Przedwiecznego",
    }
    local filter = wml.clone(location)
    local unit_filter = { side = "$side_number" }
    local requirement = wml.get_child(self.boss, "requirement")
    if requirement then
      unit_filter.formula = Inventory.formula.has_item(
        requirement.item,
        requirement.quantity
      )
    end
    table.insert(filter, wml.tag["and"]({
      wml.tag.filter_adjacent_location({ wml.tag.filter(unit_filter)}),
      wml.tag["or"]({ wml.tag.filter(unit_filter )}),
    }))
    table.insert(boss_menu, wml.tag.filter_location(filter))
    local event = {
      name = "prestart",
      wml.tag.set_menu_item(boss_menu)
    }
    table.insert(spec, wml.tag.event(event))
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
  return self:wml(hexset:random())
end

function Site:init(map, cfg)
  self.map = map
end

return Site
