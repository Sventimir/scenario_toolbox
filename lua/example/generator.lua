-- luacheck: ignore 111 112 113
Biome = require("scenario_toolbox/lua/map/biome")
Choice = require("scenario_toolbox/lua/lib/choice")
Hex = require("scenario_toolbox/lua/map/hex")
Overlay = require("scenario_toolbox/lua/map/overlay")
Predicate = require("scenario_toolbox/lua/lib/predicate")
River = require("scenario_toolbox/lua/map/river")
Spawn = require("scenario_toolbox/lua/units/spawn")
Vec = require("scenario_toolbox/lua/map/cubic_vector")

Site = {
  origin = require("scenario_toolbox/lua/example/sites/origin"),
  altar = require("scenario_toolbox/lua/example/sites/altar"),
  burial = require("scenario_toolbox/lua/example/sites/burial"),
  map_edge = require("scenario_toolbox/lua/example/sites/map_edge"),
  seed = require("scenario_toolbox/lua/example/sites/biome_seed")
}

Gen = {
  side_color = { "red", "blue", "purple" },
  biomes = {},
  units = Hex.Set:new(),
  map = Hex.Set:new(),
  frontier = Hex.Set:new()
}

function Gen:initial_spawn(biome, side)
  if #biome.spawn == 0 then return function() end end
  local available_hexes = Hex.Set:new(biome.hexes:iter())

  for h in self.units:iter() do
    available_hexes = available_hexes:diff(Hex.Set:new(h:in_circle(biome.spawn_distance)))
  end

  local function it()
    while available_hexes.size > 0 do -- luacheck: ignore 512 (this is clearly executed more than once)
      local hex = available_hexes:pop_random()
      available_hexes = available_hexes:diff(Hex.Set:new(hex:in_circle(biome.spawn_distance)))
      self.units:add(hex)
      local spawn = biome.spawn[mathx.random(#biome.spawn)]
      return spawn:wml(hex, side)
    end
  end

  return join(it)
end

function Gen:neighbours(hex)
  return filter(function(h) return h:on_map(self.map.width, self.map.height) end, hex:circle(1))
end

function Gen:make(cfg)
  self.scenario = wml.get_child(cfg, "scenario")
  self.map.width = cfg.width
  self.map.height = cfg.height
  Spawn.map.width = cfg.width
  Spawn.map.height = cfg.height
  for i = 1, cfg.player_count do
    local side = {
        side = i,
        color = self.side_color[i],
        faction = "st-heroes",
        faction_lock = false,
        leader_lock = false,
        fog = true,
        shroud = true,
        gold = 30,
        hidden = false,
        income = 0,
        village_gold = 0,
        persistent = true,
        save_id = "player" .. i,
        team_name = "Bohaterowie",
        defeat_condition = "never",
    }
    table.insert(self.scenario, wml.tag.side(side))
    table.insert(Site.origin.starting_locations, i)
  end

  local i = cfg.player_count + 1
  for biome_wml in wml.child_range(cfg, "biome") do
    local boss = {
        side = i,
        faction = "Custom",
        controller = "ai",
        allow_player = false,
        faction_lock = true,
        fog = false,
        shroud = false,
        gold = 0,
        hidden = true,
        income = 0,
        defeat_condition = "never",
    }
    local biome = Biome:new(biome_wml, boss, Site)
    self.biomes[biome.name] = biome
    table.insert(self.biomes, biome)
    boss.color = biome.color
    boss.team_name = biome.name
    table.insert(boss, wml.tag.variables({ biome = biome.name }))
    table.insert(self.scenario, wml.tag.side(boss))
    i = i + 1

    for site in iter(biome.sites) do
      site:place(self.map, self.frontier)
    end
  end

  while not self.frontier:empty() do
    local hex = self.frontier:pop_random()
    local neighbours = self.map:circle(hex, 1)
    local constr_choice = Choice.new(map(function(h) return h:propagate() end, neighbours:iter()))
    local constr = constr_choice:select()
    hex = constr.new(hex.x, hex.y)
    hex:generate(self.map)
    self.map:add(hex)
    for h in filter(function(h) return not self.map:member(h.x, h.y) end, self:neighbours(hex)) do
      self.frontier:add(h)
    end
  end

  for hex in self.map:iter() do
    self.biomes[hex.biome.name].hexes:add(hex)
    local label = hex:label()
    if label then
      table.insert(self.scenario, label)
    end
    self.scenario = wml.merge(self.scenario, hex:wml(), "append")
  end

  self.units = self.map:filter(get("starting_location"))
  self.scenario.map_data = self.map:as_map_data()

  for side in drop(cfg.player_count, wml.child_range(self.scenario, "side")) do
    local vars = wml.get_child(side, "variables")
    local biome = self.biomes[vars.biome]
    for u in self:initial_spawn(biome, side.side) do
      table.insert(side, u)
    end

    local origin_at_night = self.map.index.origin[1]:coords()
    origin_at_night.time_of_day = "chaotic"
    local respawn_args = {
      area = biome.name,
      side = side.side,
      distance = side.spawn_distance,
    }
    local biome_wml = wml.find_child(cfg, "biome", { name = biome.name })
    for spawn in wml.child_range(biome_wml, "spawn") do
      table.insert(respawn_args, wml.tag.spawn(spawn))
    end
    local respawn = {
      name = string.format("side %i turn", side.side),
      first_time_only = false,
      wml.tag.filter_condition({
          wml.tag.have_location(origin_at_night)
      }),
      wml.tag.lua({
          code = [[ nightly_respawn(...) ]],
          wml.tag.args(respawn_args)
      })
    }
    table.insert(self.scenario, wml.tag.event(respawn))
  end

  local schedule = wml.child_array(self.scenario, "time")
  for biome in iter(self.biomes) do
    table.insert(self.scenario, wml.tag.time_area(biome:time_area(iter(schedule))))
  end

  local vars = as_table(
    map(
      function(h)
        return wml.tag.sites({ x = h.x, y = h.y, type = h.site })
      end,
      self.map.index.sites:iter()
    )
  )
  vars.active = "meadows"
  table.insert(self.scenario, wml.tag.variables(vars))

  local preload = {
    name = "preload",
    id = "preload",
    first_time_only = false,
    wml.tag.lua({
        code = [[ wesnoth.dofile("~add-ons/scenario_toolbox/lua/example/init.lua") ]]
    })
  }
  table.insert(self.scenario, wml.tag.event(preload))

  return self.scenario
end

return Gen
