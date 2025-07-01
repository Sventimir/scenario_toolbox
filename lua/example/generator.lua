Vec = require("scenario_toolbox/lua/map/cubic_vector")
CartVec = require("scenario_toolbox/lua/map/carthesian_vector")
Hex = require("scenario_toolbox/lua/map/hex")
Map = require("scenario_toolbox/lua/map/map")
Biome = require("scenario_toolbox/lua/map/biome")
Side = require("scenario_toolbox/lua/wml/side")
Scenario = require("scenario_toolbox/lua/wml/scenario")
Item = require("scenario_toolbox/lua/wml/item")
Spawn = require("scenario_toolbox/lua/units/spawn")

GenHex = Hex:new()
GenHex.__index = GenHex

function GenHex:new(map, x, y, biome)
  local this = setmetatable({
      map = map,
      x = x,
      y = y,
      height = nil,
      terrain = "_off^_usr"
  }, self)
  if this.x > 0 and this.x <= map.width and this.y > 0 and this.y <= map.height then
    biome:add_hex(this)
  end
  return this
end

function GenHex:show_height()
  if not self.height then
    return "x"
  elseif self.height >= 0 then
    return string.format("[38;5;2m%i[0m", self.height)
  else
    return string.format("[38;5;1m%i[0m", - self.height)
  end
end

function GenHex:show_coord()
  if self.x == self.y then
    return self.x % 10
  else
    return " "
  end
end

function GenHex:has_feature(name)
  return self.feature and (not name or self.feature.name == name)
end

GenHex.show = GenHex.show_biome

Map.Hex = GenHex

function village_mod(prob, hex)
  if hex.height >= 0 then
    if any(function(h) h:has_feature("village") end, hex:circle(1)) then
      return Ratio.zero
    else
      return prob
    end
  else
    return arith.Ratio.zero
  end
end

function forest_mod(prob, hex)
  if hex.height >= 0  and hex.height < 2 then
    local near_forests = count(
      filter(function(h) return h:has_feature("forest") end, hex:circle(1))
    )
    return arith.Ratio:new(prob.num + near_forests, prob.denom)
  else
    return arith.Ratio.zero
  end
end

Meadows = Biome:new("meadows")
Meadows.heights = {
  [-2] = "Wo",
  [-1] = "Ww",
  [0]  = "Gg",
  [1]  = "Hh",
  [2]  = "Mm",
}
Meadows:add_feat("village", arith.Ratio:new(1, 50), { "Vhr", "Vhhr" }, village_mod)
Meadows:add_feat(
  "forest",
  arith.Ratio:new(1, 5),
  { "Fds", "Fdf", "Fds", "Fdf", "Fds", "Fdf", "Fds", "Fdf", "Fds",
  "Fdf", "Fds", "Fdf", "Fds", "Fdf", "Fds", "Fdf", "Fet" },
  forest_mod
)
Meadows.keep = "Ker"
Meadows.camp = "Cer"
Meadows.spawn = {
  passive = { "Giant Rat", "Piglet", "Woodland Boar", "Rock", "Bay Horse", "Wolf" },
  active = { "Cave Bear", "Woodland Boar", "Wolf" }
}

Forest = Biome:new("forest")
Forest.heights = {
  [-2] = "Wo",
  [-1] = "Ww",
  [0]  = "Gll",
  [1]  = "Hh",
  [2]  = "Md",
}
Forest:add_feat("forest", arith.Ratio:new(9, 10), { "Fp" }, forest_mod)
Forest.keep = "Kv"
Forest.camp = "Cv"

Snow = Biome:new("snow")
Snow.heights = {
  [-2] = "Wo",
  [-1] = "Ai",
  [0]  = "Aa",
  [1]  = "Ha",
  [2]  = "Ms",
}
Snow:add_feat("village", arith.Ratio:new(1, 100), { "Voa", "Vaa" }, village_mod)
Snow:add_feat(
  "forest",
  arith.Ratio:new(3, 10), 
  { "Fpa", "Fda", "Fma", "Fpa", "Fda", "Fma", "Fpa", "Fda", "Fma", "Feta" },
  forest_mod
)
Snow.keep = "Koa"
Snow.camp = "Coa"

Desert = Biome:new("desert")
Desert.heights = {
  [-2] = "Wo",
  [-1] = "Ww",
  [0]  = "Dd",
  [1]  = "Hd",
  [2]  = "Mdd",
}
Desert:add_feat("village", arith.Ratio:new(1, 100), { "Vdt", "Vdr" }, village_mod)
Desert:add_feat("forest", arith.Ratio:new(1, 5), { "Ftd" }, forest_mod)
Desert.keep = "Kdr"
Desert.camp = "Cdr"

Swamp = Biome:new("swamp")
Swamp.heights = {
  [-2] = "Ww",
  [-1] = "Ss",
  [0]  = "Ss",
  [1]  = "Sm",
  [2]  = "Hhd",
}
Swamp:add_feat("village", arith.Ratio:new(1, 100), { "Vhs" }, village_mod)
Swamp:add_feat(
  "forest",
  arith.Ratio:new(1, 10),
  { "Fdw", "Fmw", "Fdw", "Fmw", "Fdw", "Fmw", "Fdw", "Fmw", "Fetd" },
  forest_mod
)
Swamp.keep = "Khs"
Swamp.camp = "Chs"

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
  side_color = { "red", "blue", "green" },
  biomes = { Forest, Swamp, Desert, Snow },
  biome_centers = {},
  altars = {},
}

function Gen:border_height(hex)
  hex.height = - mathx.random(1, 2)
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
      if x == 1 then
        table.insert(self.altars, Item:forsaken_altar(all_hexes[i]))
      end
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
        function(hex) return Meadows:belongs(hex) end,
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
  local hexes = as_table(
    filter(
      function(h) return h.biome end,
      chain(self.center:circle(2), self.center:circle(3))
    )
  )
  self:encampment(hexes[mathx.random(#hexes)])

  local dim = mathx.min(self.map.height, self.map.width)
  local min_dist = mathx.max(dim / 5, 5)
  local max_dist = dim / 2 - 5
  for v in Vec.unitary.each() do
    hexes = as_table(
      filter_map(
        function(d)
          local h = self.center:translate(v:scale(d))
          return h.biome and h ~= self.meadows_altar
            and all(function(a) return a.hex ~= h end, iter(self.altars))
            and h
        end,
        take_while(function(d) return d < max_dist end, drop(min_dist, arith.nats()))
      )
    )
    if #hexes > 0 then
      self:encampment(hexes[mathx.random(#hexes)])
    end
  end

end

function Gen:make(cfg)
  local s = Scenario:new(cfg:find("scenario", 1))
  self.map = Map:new(cfg.width, cfg.height, Meadows)

  self:height_map()
  self:gen_biome_centers()
  self:expand_biomes()
  
  for hex in self.map:iter() do
    if hex.biome then hex.biome:apply_features(hex) end
  end
  
  local potential_meadows_altar = {}
  for r = mathx.floor(cfg.width / 4), cfg.width / 2 do
    for hex in self.center:circle(r) do
      if hex.height > 0 and Meadows:belongs(hex) then
        table.insert(potential_meadows_altar, hex)
      end
    end
  end
  self.meadows_altar = potential_meadows_altar[mathx.random(#potential_meadows_altar)]
  table.insert(self.altars, Item:forsaken_altar(self.meadows_altar))
  
  self.altar = Item:new("altar", self.center, {
                          image = "items/altar.png",
                          visible_in_fog = true
  })
  for hex in self.map:iter() do
    hex.terrain = hex.biome and hex.biome:terrain(hex) or "Wo"
  end

  self:place_encampments()

  local starting_positions = as_table(filter(function(h) return h.biome end, self.center:circle(1)))
  for i = 1, cfg.player_count do
    local hex = table.remove(starting_positions, mathx.random(#starting_positions))
    hex.terrain = string.format("%i %s", i, hex.terrain)
  end

  s.map_data = self.map:as_map_data()

  local schedule = s:find("time")
  s:insert(Meadows:time_area(iter(schedule)))
  for biome in iter(self.biomes) do
    s:insert(biome:time_area(iter(schedule)))
  end

  for i = 1, cfg.player_count do
    local side = Side:new({
        side = i,
        color = self.side_color[i],
        -- faction = "Random",
        faction_lock = false,
        leader_lock = false,
        fog = true,
        shroud = true,
        gold = 0,
        hidden = false,
        income = 0,
        save_id = "player" .. i,
        team_name = "Bohaterowie",
        team_user_name = "Bohaterowie",
        defeat_condition = "never",
    })
    s:insert("side", side)
  end
  s:insert("side", Side:new({
               side = cfg.player_count + 1,
               color = "black",
               faction = "Custom",
               controller = "ai",
               faction_lock = true,
               leader_lock = false,
               fog = false,
               shroud = false,
               gold = 0,
               hidden = true,
               income = 0,
               team_name = "Boss1",
               team_user_name = "Boss1",
               defeat_condition = "never",
  }))
  s:insert(self.altar:wml())
  for altar in iter(self.altars) do
    s:insert(altar:wml())
  end

  return s
end

return Gen
