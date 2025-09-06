Biome = require("scenario_toolbox/lua/map/biome")
CartVec = require("scenario_toolbox/lua/map/carthesian_vector")
Hex = require("scenario_toolbox/lua/map/hex")
Map = require("scenario_toolbox/lua/map/map")
Overlay = require("scenario_toolbox/lua/map/overlay")
Predicate = require("scenario_toolbox/lua/lib/predicate")
River = require("scenario_toolbox/lua/map/river")
Site = require("scenario_toolbox/lua/example/site")
Spawn = require("scenario_toolbox/lua/units/spawn")
Vec = require("scenario_toolbox/lua/map/cubic_vector")


local function hex_height(hex)
  if hex then return hex.height else return nil end
end

Gen = {
  side_color = { "red", "blue", "purple" },
  biomes = {},
  biome_centers = {},
}

function Gen:mean_height_around(hex)
  return mathx.round(
    arith.mean(filter_map(hex_height, hex:circle(1)))
    or mathx.random(-2, 2)
  )
end

function Gen:interior_height(hex)
  local mean = arith.mean(filter_map(hex_height, hex:circle(1))) or 0
  local roll = mathx.random(-1, 2)
  hex.height = mathx.max(-2, mathx.min(2, mathx.round(mean + (roll / 2))))
end

function Gen:river(hexsets)
  local potential_springs = hexsets.interior:filter(function(h)
      local dist = h:distance(self.center)
      return dist > 7 and dist < 11
  end)
  local river = River:new(potential_springs, hexsets.border)
  river:generate()
end

function Gen:heightmap()
  hexes = Hex.Set:new(self.map:iter())
  self.center = self.map:get(self.map.height / 2, self.map.width / 2)

  for hex in self.center:in_circle(2) do
    hex.height = 0
    hex.terrain = self.center.biome.terrain[self.center.height]
    hexes:remove(hex)
  end

  local hexsets = hexes:partition(function(h)
      if mathx.min(h.x, h.y, self.map.width - h.x, self.map.height - h.y) > 3 then
        return "interior"
      else
        return "border"
      end
  end)
  for hex in hexsets.border:iter() do
    local border_dist = mathx.min(hex.x, hex.y, self.map.width - hex.x, self.map.height - hex.y)
    hex.height = mathx.round(mathx.random(0, border_dist) / 3) - 2
    self.biomes.ocean:add_hex(hex)
  end

  self:river(hexsets)
  local dim = mathx.sqrt((self.map.width / 2) ^ 2 + (self.map.height / 2) ^ 2)
  local r = 3
  while r < dim do
    for hex in self.center:circle(r) do
      if hex.height == 0 then
        self:interior_height(hex)
      end
    end
    r = r + 1
  end
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
  while hexes.size > 0 do
    local hex = hexes:pop_random()
    local biome = self:biomeset(hex)
    if biome then
      hexes = hexes:diff(Hex.Set:new(hex:in_circle(10)))
      biome:add_hex(hex)
      table.insert(self.biome_centers, hex)
    end
  end
end

function Gen:biomeset(hex)
  local distance = hex:distance(self.center)
  local biomes = {}
  local total_prob = 0
  for biome in iter(self.biomes) do
    local probability = mathx.round(
      1000 * biome.distance_from_center:probability(distance)
    )
    table.insert(biomes, { prob = probability, biome = biome })
    total_prob = total_prob + probability
  end
  if total_prob > 0 then
    local roll = mathx.random(0, total_prob - 1)
    for b in iter(biomes) do
      if roll < b.prob then
        return b.biome
      else
        roll = roll - b.prob
      end
    end
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
        local valid_neighbours = count(
          filter(
            function(h) return center.biome:belongs(h) end,
            hex:circle(1)
          )
        )
        if hex:distance(self.center) > 3 and mathx.random(0, r) < 2 * valid_neighbours then
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
  if #biome.spawn == 0 then return function() end end
  local available_hexes = Hex.Set:new(biome.hexes:iter())

  for h in self.units:iter() do
    available_hexes = available_hexes:diff(Hex.Set:new(h:in_circle(biome.spawn_distance)))
  end

  local function it()
    while available_hexes.size > 0 do
      local hex = available_hexes:pop_random()
      available_hexes = available_hexes:diff(Hex.Set:new(hex:in_circle(biome.spawn_distance)))
      self.units:add(hex)
      local spawn = biome.spawn[mathx.random(#biome.spawn)]
      return spawn:wml(hex, side)
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

  local i = cfg.player_count + 1
  for biome_wml in wml.child_range(cfg, "biome") do
    boss = {
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
    biome = Biome:new(biome_wml, boss)
    self.biomes[biome.name] = biome
    table.insert(self.biomes, biome)
    boss.color = biome.color
    boss.team_name = biome.name
    table.insert(boss, wml.tag.variables({ biome = biome.name }))
    table.insert(s, wml.tag.side(boss))
    i = i + 1
  end
 
  self.map = Map:new(cfg.width, cfg.height, self.biomes.meadows)
  Site:init(self.map, self.biomes, cfg)

  self:heightmap()
  self:gen_biome_centers()
  self:expand_biomes()

  self.sites = Hex.Set:new()
  local hexes = Hex.Set:new(self.map:iter())
  local camp = Hex.Set:new(self.center:circle(3)):pop_random()
  local ov = any(Predicate:has("name", "castle"), iter(self.biomes.meadows.overlay))
  local overlayed = ov:apply(camp)
  hexes = hexes:diff(overlayed)

  while hexes.size > 0 do
    local hex = hexes:random()
    hex.terrain = hex.biome.terrain[hex.height]
    ov = Overlay.select(hex.biome.overlay, hex)
    if ov then
      local overlayed = ov:apply(hex)
      hexes = hexes:diff(overlayed)
    end
  end

  hexes = Hex.Set:new(
    filter(
      function(h) return not (h:has_village() or h:is_border()) end,
      self.map:iter()
    )
  )
  local origin = Site.origin:new()
  s = wml.merge(s, origin:wml(self.center), "append")
  self.center.site = origin.name
  self.sites:add(self.center)
  hexes:remove(self.center)

  for biome in iter(self.biomes) do
    for site in iter(biome.sites) do
      for site_wml in site:place(self.center, hexes:intersect(biome.hexes)) do
        s = wml.merge(s, site_wml, "append")
        for item in wml.child_range(site_wml, "item") do
          local hex = self.map:get(item.x, item.y)
          hexes:remove(item)
          hex.site = site.name
          self.sites:add(hex)
        end
      end
    end
  end

  self.units = Hex.Set:new()

  local starting_positions = Hex.Set:new(self.center:circle(1))
  for i = 1, cfg.player_count do
    local hex = starting_positions:pop_random()
    hex.terrain = string.format("%i %s", i, hex.terrain)
    self.units:add(hex)
  end

  for hex in self.map:iter() do
    local label = hex:label()
    if label then
      table.insert(s, wml.tag.label(label))
    end
  end

  s.map_data = self.map:as_map_data()

  for side in drop(cfg.player_count, wml.child_range(s, "side")) do
    local vars = wml.get_child(side, "variables")
    local biome = self.biomes[vars.biome]
    for u in self:initial_spawn(biome, side.side) do
      table.insert(side, u)
    end

    local origin_at_night = self.center:coords()
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
    table.insert(s, wml.tag.event(respawn))
  end

  local schedule = wml.child_array(s, "time")
  for biome in iter(self.biomes) do
    table.insert(s, wml.tag.time_area(biome:time_area(iter(schedule))))
  end

  local vars = as_table(
    map(
      function(h)
        return wml.tag.sites({ x = h.x, y = h.y, type = h.site })
      end,
      self.sites:iter()
    )
  )
  vars.active = "meadows"
  table.insert(s, wml.tag.variables(vars))

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
