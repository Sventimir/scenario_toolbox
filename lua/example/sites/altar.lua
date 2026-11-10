local Hex = require("scenario_toolbox/lua/map/hex")
local Inventory = require("scenario_toolbox/lua/units/inventory")
local Objectives = require("scenario_toolbox/lua/example/objectives")
local Prob = require("scenario_toolbox/lua/lib/probability")

local Altar = {}
local __Altar = { __index = Altar }

function Altar.new(biome, spec)
  local dist = wml.get_child(spec, "distance_from_origin")
  local this = {
    name = string.format("altar(%s)", biome.name),
    biome = biome,
    distance = Prob.Normal:new(dist.mean, dist.standard_deviation),
    min_dist = dist.minimum or 1,
    max_dist = dist.maximum or mathx.huge,
    spawn = wml.get_child(spec, "spawn"),
    boss = wml.get_child(spec, "boss"),
    boss_id = string.format("%s-boss", biome.name),
    variables = { description = spec.description }
  }
  local boss_title = wml.get_child(this.boss, "title")
  this.variables.title = string.format("Ołtarz %s", boss_title.genetive)

  return setmetatable(this, __Altar)
end

function Altar:boss_defeated_action()
  local next_altar = wml.get_child(self.boss, "next_altar")
  if next_altar then
    return {
      wml.tag.set_variable({
          name = "active",
          value = next_altar.biome
      }),
      wml.tag.objectives(
        Objectives.wml(
          wml.get_child(next_altar, "name"),
          wml.get_child(next_altar, "title"),
          wml.get_child(next_altar, "biome")
        )
      )
    }
  else
    return { wml.tag.endlevel({ result = "victory" }) }
  end
end

Altar.Hex = setmetatable({ image = "items/altar-evil.png", site = "altar" }, Hex.__Gen)
Altar.__Hex = { __index = Altar.Hex }

function Altar.Hex.new(x, y)
  local this = setmetatable(Hex.Gen.new(x, y), Altar.__Hex)
  this.site = "altar"
  return this
end

function Altar.Hex:generate(map)
  local neighbours = map:circle(self, 1)
  local height = Prob.Normal:new(1, 1)
  self.height = height:sample(0, 2)
  self.overlay = self:gen_overlay(neighbours, map)
end

function Altar.Hex:propagate() -- luacheck: ignore 212 (usused 'self' required by interface)
  return { option = Hex.Gen, weight = 1 }
end

function Altar.Hex:wml()
  local spec = {
    wml.tag.item({
        x = self.x,
        y = self.y,
        name = self.site,
        image = self.image,
        visible_in_fog = true,
        wml.tag.variables(self.prototype.variables)
    })
  }
  local neighbourhood = wml.clone(self:coords())
  neighbourhood.radius = 1
  if self.prototype.spawn then
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
    if self.prototype.boss then
      local absent_boss = { wml.tag.have_unit({ id = self.prototype.boss_id }) }
      table.insert(filter, wml.tag["not"](absent_boss))
    end
    local spawn = wml.merge(wml.clone(self.prototype.spawn), self:coords(), "append")
    spawn.side = self.biome.side.side
    table.insert(spawn_event, wml.tag.filter_condition(filter))
    table.insert(spawn_event, wml.tag.spawn(spawn))
    table.insert(spec, wml.tag.event(spawn_event))
  end
  if self.prototype.boss then
    local unit_filter = { side = "$side_number" }
    local requirement = wml.get_child(self.prototype.boss, "requirement")
    if requirement then
      unit_filter.formula = Inventory.formula.has_item(
        requirement.item,
        requirement.quantity
      )
    end
    local boss_title = wml.get_child(self.prototype.boss, "title")
    local boss_menu = {
      id = string.format("%s-summon-menu", self.biome.name),
      description = string.format("Przywołanie %s", boss_title.genetive),
    }
    local filter = {
      x = self.x,
      y = self.y,
      wml.tag["and"]({
          wml.tag.filter_adjacent_location({ wml.tag.filter(unit_filter) }),
          wml.tag["or"]({ wml.tag.filter(unit_filter) })
      }),
    }
    table.insert(boss_menu, wml.tag.filter_location(filter))
    local unit = wml.clone(self.prototype.boss)
    wml.remove_child(unit, "requirement")
    local spawn = wml.merge({ wml.tag.unit(unit) }, self:coords(), "append")
    local time_area_id = string.format("%s-boss-fight", self.biome.name)
    local boss_defeat_id = string.format("%s-boss-defeated", self.biome.name)
    spawn.side = self.biome.side.side
    local cmd = {
      wml.tag.store_unit({
          variable = "summoner",
          wml.tag.filter(unit_filter),
      }),
      wml.tag.time_area({
          id = time_area_id,
          x = "$x1", y = "$y1", radius = 3,
          wml.tag.time({
              name = string.format("Aura %s", boss_title.genetive),
              description = "Wokół Przedwiecznej Istoty panuje ciemność i burza z piorunami.",
              image = "misc/time-schedules/schedule-midnight.png",
              lawful_bonus = -25,
              red = -75,
              green = -45,
              blue = -13,
          })
      }),
      wml.tag.spawn(spawn),
      wml.tag.event(
        wml.merge({
            name = "die",
            id = boss_defeat_id,
            first_time_only = false,
            wml.tag.filter({ id = unit.id }),
            wml.tag.remove_time_area({ id = time_area_id }),
            wml.tag.event({ id = boss_defeat_id, remove = true }),
        },
        self.prototype:boss_defeated_action(),
        "append"
        )
      )
    }
    if requirement then
      local offering = {
        wml.tag.filter(unit_filter),
        wml.tag.remove({
            item = requirement.item,
            quantity = requirement.quantity,
        }),
      }
      table.insert(cmd, wml.tag.inventory(offering))
    end
    if self.prototype.boss.dialogue then
      local d = {
        filename = self.prototype.boss.dialogue
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

function Altar:place(map, frontier)
  local origin = map.index.origin[1]
  local r = self.distance:sample_int(self.min_dist, self.max_dist)
  local excluded = map:union(frontier)
  if map.index.altars then
    for altar in map.index.altars:iter() do
      excluded = excluded:union(Hex.Set:new(altar:in_circle(10)))
    end
  else
    excluded = Hex.Set:new()
    map:add_index("altars", function(h) return h.site == "altar" end)
  end
  local hexset = Hex.Set:new(origin:circle(r)):diff(excluded)
  local hex = self.Hex.new(hexset:random())
  hex.biome = self.biome
  hex:generate(map)
  hex.prototype = self
  map:add(hex)
  for h in hex:circle(1) do
    frontier:add(h)
  end
end

return Altar
