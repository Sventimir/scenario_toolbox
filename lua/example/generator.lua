Vec = require("scenario_toolbox/lua/map/cubic_vector")
CartVec = require("scenario_toolbox/lua/map/carthesian_vector")
Hex = require("scenario_toolbox/lua/map/hex")
Map = require("scenario_toolbox/lua/map/map")
Biome = require("scenario_toolbox/lua/map/biome")
Side = require("scenario_toolbox/lua/wml/side")
Scenario = require("scenario_toolbox/lua/wml/scenario")
Item = require("scenario_toolbox/lua/wml/item")
Spawn = require("scenario_toolbox/lua/units/spawn")
Biomes = require("scenario_toolbox/lua/example/biomes")
Predicate = require("scenario_toolbox/lua/lib/predicate")


function Item:forsaken_altar(hex)
  return self:new("altar-" .. hex.biome.name, hex, {
                    image = "items/altar-evil.png",
                    visible_in_fog = true
  })
end


local function hex_height(hex)
  if hex then return hex.height else return nil end
end

Gen = {
  side_color = { "red", "blue", "purple" },
  biomes = { Biomes.forest, Biomes.swamp, Biomes.desert, Biomes.snow },
  biome_centers = {},
}

function Gen:border_height(hex)
  Ocean:add_hex(hex)
  hex.height = - mathx.min(2, mathx.floor(mathx.random(1, 6) / 2))
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
    if hex.biome and hex.height < -1 then
      Ocean:add_hex(hex)
    end
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
end

function Gen:gen_biome_centers()
  local max_radius = mathx.max(self.map.height, self.map.width) / 2
  local dist_unit = (self.map.height + self.map.width) / 20
  local dist = 1
  for biome in iter(self.biomes) do
    local count = mathx.random(5 - dist, 7 - dist)
    local base_dist = dist * dist_unit
    local all_hexes = {}
    for r = dist * dist_unit, max_radius do
      for hex in self.center:circle(r) do
        if hex.height > 0 then
          table.insert(all_hexes, hex)
        end
      end
    end
    local initials = {}
    for x = 1, count do
      local i = mathx.random(#all_hexes)
      biome:add_hex(all_hexes[i])
      table.insert(initials, all_hexes[i])
      table.insert(self.biome_centers, all_hexes[i])
      table.remove(all_hexes, i)
    end

    dist = dist + 1
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

function Gen:encampment(hex)
  local v = Vec.unitary.random()
  local rotations = { Vec.unitary.clockwise, Vec.unitary.counterclockwise }
  local camp = { hex:translate(v), hex:translate(rotations[mathx.random(2)](v)) }
  hex.terrain = hex.biome.keep
  for h in iter(camp) do
    h.biome = nil
    h.terrain = hex.biome.camp
  end
  hex.biome = nil
end

function Gen:place_encampments()
  local hexes = Hex.Set:new(
    filter(
      function(h) return h.biome and h.biome.keep end,
      chain(self.center:circle(2), self.center:circle(3))
    )
  )
  self:encampment(hexes:random())

  local dim = mathx.min(self.map.height, self.map.width)
  local min_dist = mathx.max(dim / 5, 5)
  local max_dist = dim / 2 - 5
  for v in Vec.unitary.each() do
    hexes = Hex.Set:new(
      filter_map(
        function(d)
          local h = self.center:translate(v:scale(d))
          if h.biome and all(function(name) return Biomes[name].altar ~= h end, pairs(Biomes)) then
            return h
          end
        end,
        take_while(function(d) return d < max_dist end, drop(min_dist, arith.nats()))
      )
    )
    if #hexes > 0 then
      self:encampment(hexes:random())
    end
  end
end

function Gen:initial_spawn(biome, side)
  local wml = WML:new()
  local available_hexes = Hex.Set:new(biome.hexes:iter())
  local spawns = biome.spawn.passive or {}

  for h in self.units:iter() do
    available_hexes = available_hexes:diff(Hex.Set:new(h:in_circle(5)))
  end

  while #spawns > 0 and available_hexes.size > 0 do
    local hex = available_hexes:random()
    available_hexes:remove(hex)
    local s = spawns[mathx.random(#spawns)]:wml(hex, side)
    wml:merge(s)
    available_hexes = available_hexes:diff(Hex.Set:new(hex:in_circle(5)))
    self.units:add(hex)
  end

  return wml
end

function Gen:make(cfg)
  local s = Scenario:new(cfg:find("scenario", 1))
  self.map = Map:new(cfg.width, cfg.height, Biomes.meadows)

  self:height_map()
  self:gen_biome_centers()
  self:expand_biomes()
  
  for hex in self.map:iter() do
    if hex.biome then hex.biome.features:assign(hex) end
  end
  
  local potential_meadows_altar = Hex.Set:new(
    filter(
      function(h)
        return h.height >= 0 and h:distance(self.center) >= mathx.floor(cfg.width / 4)
          and all(function(n) return n.biome and n.biome.name == "meadows" end, h:in_circle(1))
      end,
      Biomes.meadows.hexes:iter()
    )
  )
  self.meadows_altar = potential_meadows_altar:random()
  Biomes.meadows.altar = Item:forsaken_altar(self.meadows_altar)

  for biome in iter(self.biomes) do
    local r = 3
    while not biome.altar do
      local available_hexes = Hex.Set:new(
        filter(
          function(h)
            return h.height >= 0 and all(
              function(n)
                return n.biome and n.biome.name == biome.name
              end,
              h:in_circle(r))
          end,
          biome.hexes:iter()
        )
      )
      if available_hexes.size > 0 then
        biome.altar = Item:forsaken_altar(available_hexes:random())
      else
        r = r - 1
      end
    end
  end
  
  self.altar = Item:new("altar", self.center, {
                          image = "items/altar.png",
                          visible_in_fog = true
  })
  for hex in self.map:iter() do
    hex.terrain = hex.biome and hex.biome:terrain(hex) or "Wo"
    if hex.feature then
      hex.feature:apply(hex, s)
    end
  end

  self.units = Hex.Set:new()

  local starting_positions = as_table(filter(function(h) return h.biome end, self.center:circle(1)))
  for i = 1, cfg.player_count do
    local hex = table.remove(starting_positions, mathx.random(#starting_positions))
    hex.terrain = string.format("%i %s", i, hex.terrain)
    self.units:add(hex)
  end

  s.map_data = self.map:as_map_data()

  local schedule = s:find("time")
  s:insert(Biomes.meadows:time_area(iter(schedule)))
  for biome in iter(self.biomes) do
    s:insert(biome:time_area(iter(schedule)))
  end
  local side_counter = 0

  for i = 1, cfg.player_count do
    local side = Side:new({
        side = i,
        color = self.side_color[i],
        faction = "st-heroes",
        faction_lock = false,
        leader_lock = false,
        fog = true,
        shroud = true,
        gold = 50,
        hidden = false,
        income = 0,
        village_gold = 0,
        persistent = true,
        save_id = "player" .. i,
        team_name = "Bohaterowie",
        defeat_condition = "never",
    })
    s:insert("side", side)
    side_counter = i
  end

  for biome in iter(Biomes) do
    side_counter = side_counter + 1
    boss = Side:new({
        side = side_counter,
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
    })
    if biome.altar then
      local vars = WML:tag("variables", {
                             biome = biome.name,
                             WML:tag("altar", {
                                       x = biome.altar.x,
                                       y = biome.altar.y
                             })
      })
      boss:insert(vars)
    end
    boss:merge(self:initial_spawn(biome, side_counter))

    s:insert("side", boss)
  end

  s:insert(self.altar:wml())
  s:insert("variables", { active = "meadows" })

  s:insert("event", {
             name = "preload",
             id = "preload",
             first_time_only = false,
             {"lua", WML:new({
                  code = [[ wesnoth.dofile("~add-ons/scenario_toolbox/lua/example/init.lua") ]]
             })}
  })

  return s
end

return Gen
