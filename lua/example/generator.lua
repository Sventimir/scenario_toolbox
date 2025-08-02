Vec = require("scenario_toolbox/lua/map/cubic_vector")
CartVec = require("scenario_toolbox/lua/map/carthesian_vector")
Hex = require("scenario_toolbox/lua/map/hex")
Map = require("scenario_toolbox/lua/map/map")
Biome = require("scenario_toolbox/lua/map/biome")
Spawn = require("scenario_toolbox/lua/units/spawn")
Biomes = require("scenario_toolbox/lua/example/biomes")
Predicate = require("scenario_toolbox/lua/lib/predicate")


local function hex_height(hex)
  if hex then return hex.height else return nil end
end

Gen = {
  side_color = { "red", "blue", "purple" },
  biome_centers = {},
}

function Gen:border_height(hex)
  hex.height = - mathx.min(2, mathx.floor(mathx.random(1, 6) / 2))
  Biomes.ocean:add_hex(hex)
end

function Gen:fjord_height(hex)
  local mean = arith.round(arith.mean(filter_map(hex_height, hex:circle(1))))
  local h = mean + mathx.random(-1, 1)
  if h >= 0 and mean <= 0 then
    h = h + mathx.random(0, 1)
  end
  hex.height = mathx.max(-2, mathx.min(2, h))
end

function Gen:interior_height(hex)
  local mean = arith.round(arith.mean(filter_map(hex_height, hex:circle(1))))
  local d = arith.round(mathx.random(-2, 2) / 2)
  if d > 0 then
    d = d + mathx.random(0, 1)
  end
  hex.height = mathx.max(-2, mathx.min(2, mean + d))
end

function Gen:height_map()
  local x = 0
  local y = 0
  local next_movement = cycle({ CartVec.east, CartVec.south, CartVec.west, CartVec.north })
  local v = next_movement()
  local hex = self.map:get(x, y)
  local set_height = self.border_height

  while not hex.height do
    set_height(self, hex)
    if hex.height < -1 then
      Biomes.ocean:add_hex(hex)
    end
    hex.biome:add_hex(hex) -- this is a hacky way of setting terrain
    x, y = v:translate(x, y)
    hex = self.map:get(x, y)
    if not hex or hex.height then
      local next_v = next_movement()
      x, y = (next_v - v):translate(x, y)
      hex = self.map:get(x, y)
      v = next_v
    end
    if x == 3 and y == 3 then
      set_height = self.fjord_height
    elseif x == 10 and y == 10 then
      set_height = self.interior_height
    end
  end

  self.center = hex
  self.center.height = 0
  self.center.terrain = self.center.biome.heights[0]
end

function Gen:gen_biome_centers()
  local hexes = Hex.Set:new(
    filter(
      function(h) 
        return h:distance(self.center) > 10 and h.biome.name == "meadows"
      end,
      self.map:iter()
    )
  )
  local biomes = cycle(Biomes)
  while hexes.size > 0 do
    local biome = biomes()
    local hex = hexes:pop_random()
    hexes = hexes:diff(Hex.Set:new(hex:in_circle(10)))
    biome:add_hex(hex)
    table.insert(self.biome_centers, hex)
  end
end

function Gen:expand_biomes()
  local r = 1
  while #self.biome_centers > 0 do
    for center_idx, center in ipairs(self.biome_centers) do
      local new_hexes = {}
      local potential_hexes = filter(
        Predicate:has("name", "meadows"):contra_map(get("biome")),
        center:circle(r)
      )
      for hex in potential_hexes do
        local valid_neighbours = as_table(
          filter(
            function(h) return center.biome:belongs(h) end,
            hex:circle(1)
          )
        )
        if hex:distance(self.center) > 3 and mathx.random(0, r) < 2 * #valid_neighbours then
          table.insert(new_hexes, hex)
          center.biome:add_hex(hex)
        end
      end
      if #new_hexes == 0 then
        table.remove(self.biome_centers, center_idx)
      end
    end
    r = r + 1
  end
end

function Gen:initial_spawn(biome, side)
  local available_hexes = Hex.Set:new(biome.hexes:iter())
  local spawns = biome.spawn.passive or {}

  for h in self.units:iter() do
    available_hexes = available_hexes:diff(Hex.Set:new(h:in_circle(5)))
  end

  local function it()
    while #spawns > 0 and available_hexes.size > 0 do
      local hex = available_hexes:random()
      available_hexes:remove(hex)
      available_hexes = available_hexes:diff(Hex.Set:new(hex:in_circle(5)))
      self.units:add(hex)
      return spawns[mathx.random(#spawns)]:wml(hex, side.side)
    end
  end

  return join(it)
end

function Gen:make(cfg)
  local s = wml.get_child(cfg, "scenario")
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
    table.insert(s, wml.tag.side(side))
  end

  for i, biome in zip(drop(cfg.player_count, arith.nats()), iter(Biomes)) do
    boss = {
        side = i,
        color = biome.colour,
        faction = "Custom",
        controller = "ai",
        allow_player = false,
        faction_lock = true,
        fog = false,
        shroud = false,
        gold = 0,
        hidden = true,
        income = 0,
        team_name = biome.name,
        defeat_condition = "never",
    }
    local vars = { biome = biome.name, wml.tag.sites({}) }
    table.insert(boss, wml.tag.variables(vars))
    table.insert(s, wml.tag.side(boss))
  end
 
  self.map = Map:new(cfg.width, cfg.height, Biomes.meadows)

  self:height_map()
  self:gen_biome_centers()
  self:expand_biomes()

  Biome.Feature.center = self.center
  self.center.feature = Biomes.meadows.features:find("origin")
  self.center.feature:apply(self.center, s)

  local hexes = Hex.Set:new(self.map:iter())
  while hexes.size > 0 do
    local hex = hexes:pop_random()
    if hex.biome then
      f = hex.biome.features:assign(hex)
      if f then f:apply(hex, s) end
    end
  end

  self.units = Hex.Set:new()

  local starting_positions = as_table(
    filter(function(h) return h.biome end, self.center:circle(1))
  )
  for i = 1, cfg.player_count do
    local hex = table.remove(starting_positions, mathx.random(#starting_positions))
    hex.terrain = string.format("%i %s", i, hex.terrain)
    self.units:add(hex)
  end

  s.map_data = self.map:as_map_data()

  for side in drop(cfg.player_count, wml.child_range(s, "side")) do
    local vars = wml.get_child(side, "variables")
    local biome = Biomes[vars.biome]
    for u in self:initial_spawn(biome, boss) do
      table.insert(side, u)
    end
  end

  local schedule = wml.child_array(s, "time")
  for biome in iter(Biomes) do
    table.insert(s, wml.tag.time_area(biome:time_area(iter(schedule))))
  end

  table.insert(s, wml.tag.variables({ active = "meadows" }))

  local preload = {
    name = "preload",
    id = "preload",
    first_time_only = false,
    wml.tag.lua({
        code = [[ wesnoth.dofile("~add-ons/scenario_toolbox/lua/example/init.lua") ]]
    })
  }
  table.insert(s, wml.tag.event(preload))

  return s
end

return Gen
