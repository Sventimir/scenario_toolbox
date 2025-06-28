Vec = require("scenario_toolbox/lua/cubic_vector")
CartVec = require("scenario_toolbox/lua/carthesian_vector")
Hex = require("scenario_toolbox/lua/hex")
Map = require("scenario_toolbox/lua/map")
Side = require("scenario_toolbox/lua/side")
Scenario = require("scenario_toolbox/lua/scenario")
Biome = require("scenario_toolbox/lua/biome")

GenHex = Hex:new()
GenHex.__index = GenHex

function GenHex:new(map, x, y, biome)
  return setmetatable({
      map = map,
      x = x,
      y = y,
      biome = biome,
      height = nil,
      terrain = "_off^_usr"
  }, self)
end

function GenHex:show_biome()
  return self.biome.symbol
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

GenHex.show = GenHex.show_biome

Map.Hex = GenHex

Meadows = Biome:new("meadows", "[38;5;34mM[0m", "Gg")
Meadows.heights = {
  [-2] = "Wo",
  [-1] = "Ww",
  [0]  = "Gg",
  [1]  = "Hh",
  [2]  = "Mm",
}
Meadows.forest = { probability = 5, "Fds", "Fdf", "Fds", "Fdf", "Fds", "Fdf", "Fds", "Fdf", "Fds", "Fdf", "Fds", "Fdf", "Fds", "Fdf", "Fds", "Fdf", "Fet" }

Forest = Biome:new("forest", "[38;5;10mF[0m", "Gll")
Forest.heights = {
  [-2] = "Wo",
  [-1] = "Ww",
  [0]  = "Gll",
  [1]  = "Hh",
  [2]  = "Md",
}
Forest.forest = { probability = 9, "Fp" }

Snow = Biome:new("snow", "[38;5;15mS[0m", "Dd")
Snow.heights = {
  [-2] = "Wo",
  [-1] = "Ai",
  [0]  = "Aa",
  [1]  = "Ha",
  [2]  = "Ms",
}
Snow.forest = { probability = 3, "Fpa", "Fda", "Fma", "Fpa", "Fda", "Fma", "Fpa", "Fda", "Fma", "Feta" }

Desert = Biome:new("desert", "[38;5;11mD[0m", "Dd")
Desert.heights = {
  [-2] = "Wo",
  [-1] = "Ww",
  [0]  = "Dd",
  [1]  = "Hd",
  [2]  = "Mdd",
}
Desert.forest = { probability = 2, "Ftd" }

Swamp = Biome:new("swamp", "[38;5;2mB[0m", "Dd")
Swamp.heights = {
  [-2] = "Ww",
  [-1] = "Ss",
  [0]  = "Ss",
  [1]  = "Sm",
  [2]  = "Hhd",
}
Swamp.forest = { probability = 3, "Fdw", "Fmw", "Fdw", "Fmw", "Fdw", "Fmw", "Fdw", "Fmw", "Fetd" }


local function hex_height(hex)
  if hex then return hex.height else return nil end
end

Gen = {
  side_color = { "red", "blue", "green" },
  biomes = { Forest, Swamp, Desert, Snow },
  biome_centers = {},
  altars = {},
}

function Gen:paint_circle(center, radius, biome, overwrite)
  for d = 1, radius do
    for hex in center:circle(d) do
      if hex.biome._nil or overwrite then
        hex.biome = biome
      end
    end
  end
end

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
    local all_hexes = as_table(chain(
      table.unpack(as_table(map(
        function(r) return self.center:circle(r - 1) end,
        take_while(function(r) return r < max_radius end, drop(dist * dist_unit, arith.nats()))
      ))))
    )
    local initials = {}
    for x = 1, count do
      local i = mathx.random(#all_hexes)
      table.insert(initials, all_hexes[i])
      table.insert(self.biome_centers, all_hexes[i])
      if x == 1 then
        table.insert(self.altars, all_hexes[i])
      end
      all_hexes[i].biome = biome
      table.remove(all_hexes, i)
    end

    dist = dist + 1
  end
end

function Gen:expand_biomes()
  for center in iter(self.biome_centers) do
    local new_hexes = { center }
    local r = 1
    while #new_hexes > 0 do
      new_hexes = {}
      for hex in center:circle(r) do
        local valid_neighbours = as_table(filter(function(h) return h.biome.name == center.biome.name end, hex:circle(1)))
        if mathx.random(0, r) < 2 * #valid_neighbours then
          table.insert(new_hexes, hex)
          hex.biome = center.biome
        end
      end
      r = r + 1
    end
  end
end

function Gen:plant_forests()
  for hex in self.map:iter() do
    local neighbour_forest = fold(arith.add, 0, map(function(h) return h.forest and 1 or 0 end, hex:circle(1)))
    local chance = hex.biome.forest.probability + neighbour_forest
    if hex.height >= 0 and hex.height < 2 and mathx.random(0, 9) < chance then
      hex.forest = hex.biome.forest[mathx.random(#hex.biome.forest)]
    end
  end
end

function Gen:make(cfg)
  local s = Scenario:new(cfg:find("scenario", 1))

  for i = 1, cfg.player_count do
    local side = Side:new({
        side = i,
        color = self.side_color[i],
        faction = "Custom",
        faction_lock = true,
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

  self.map = Map:new(cfg.width, cfg.height, Meadows)

  self:height_map()
  self:gen_biome_centers()
  self:expand_biomes()
  self:plant_forests()
  
  local potential_boss_locations = as_table(self.center:circle(cfg.width / 2 - 1))
  self.boss_loc = potential_boss_locations[mathx.random(#potential_boss_locations)]
  self.boss_loc.biome = Meadows
  self:paint_circle(self.boss_loc, 3, Meadows)
  

  for hex in self.map:iter() do
    hex.terrain = hex.biome:terrain(hex)
    if hex.forest then
      hex.terrain = hex.terrain .. "^" .. hex.forest
    end
  end

  s.map_data = self.map:as_map_data()
  return s
end

return Gen
