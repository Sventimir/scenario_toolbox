Hex = require("scenario_toolbox/lua/map/hex")
Biome = require("scenario_toolbox/lua/map/biome")
Spawn = require("scenario_toolbox/lua/units/spawn")


local function altar(biome)
  local altar = Biome.Feature.site(
    "altar",
    "items/altar-evil.png",
    biome,
    function(self, hex)
      local near_other_biome = any(
        function(h)
          return h.biome.name ~= hex.biome.name
        end,
        hex:in_circle(3)
      )
      local dist = hex:distance(Biome.Feature.center)
      if hex.height < 0 or near_other_biome or dist < 10 then
        return { weight = 0, feat = self }
      else
        return { weight = 100, feat = self }
      end
    end,
    function(self, hex, scenario)
      hex.biome.features:remove(self.name)
      hex.biome.altar = hex
    end,
    biome.spawn.active
  )

  function altar:assign(hex)
    hex.feature = self
    hex.biome.features:remove(self.name)
  end

  function altar:spawn(hexes)
    if #hexes > 0 and #self.spawns > 0 and wml.variables.active == biome.name then
      local spawn = self.spawns[mathx.random(#self.spawns)]
      local coords, _ = hexes[1]
      local altar = Hex:from_wesnoth(wesnoth.map.get(coords.x, coords.y))
      spawn:spawn(altar, self.biome:side().side)
    end
  end

  function altar:description(speaker)
    return {
      portrait = speaker,
      title = "Ołtarz Przedwiecznego",
      message = "Oto ołtarz Shazzy. Wyryty na nim napis głosi: \"Któryż pies oprze się rzuconej mu kości?\""
    }
  end

  function altar:micro_ai() return nil end
  
  return altar
end

local function origin(biome)
  local origin = Biome.Feature.site(
    "origin",
    "items/altar.png",
    biome,
    function(self, hex) return { weight = 0, feat = self } end,
    function(self, hex) end,
    {}
  )

  function origin:micro_ai() return nil end

  function origin:description(speaker)
    return {
      portrait = speaker,
      title = "Ołtarz Baziola",
      message = "Na tym ołtarzu Praojciec Baziol przyjmuje ofiary z pokonanych przedwiecznych. "
        .. "Obecnie naszym celem jest Shazza, której szukać należy na łąkach."
    }
  end

  return origin
end

local Biomes = {}

Biomes.ocean = Biome:new("ocean")
Biomes.meadows = Biome:new("meadows")
Biomes.forest = Biome:new("forest")
Biomes.swamp = Biome:new("swamp")
Biomes.snow = Biome:new("snow")
Biomes.desert = Biome:new("desert")

Biomes.ocean.heights = {
  [-2] = "Wog",
  [-1] = "Wo",
  [0]  = "Ww",
  [1]  = "Wwr",
  [2]  = "Ds"
}
Biomes.ocean.colour = "teal"
Biomes.ocean:add_feat(Biome.Feature.none(1))

Biomes.meadows.heights = {
  [-2] = "Wo",
  [-1] = "Ww",
  [0]  = "Gg",
  [1]  = "Hh",
  [2]  = "Mm",
}
Biomes.meadows.colour = "green"
Biomes.meadows.spawn = {
  passive = { 
    Spawn:family("Woodland Boar", "Piglet", 2, 4),
    Spawn:new("Raven"),
    Spawn:new("Giant Rat"),
    Spawn:new("Bay Horse"),
  },
  active = {
    Spawn:wolf_pack("Wolf", 0, 1),
  },
  boss = Spawn:new("Great Wolf", {
                     max_hitpoints = 90,
                     name = "Shazza",
                     id = "meadows-boss",
  })
}
Biomes.meadows:add_feat(altar(Biomes.meadows))
Biomes.meadows:add_feat(
  Biome.Feature.castle(
    "Ker", "Cer",
    function(feat, hex)
      local center_dist = hex:distance(Biome.Feature.center)
      local castles = count(
        filter(
          function(h) return h.feature and h.feature.name == "castle" end,
          hex:in_circle(5)
        )
      )
      if castles > 0 or hex.height < 0 or center_dist < 7 then
        return { weight = 0, feat = feat }
      else
        return { weight = 1, feat = feat }
      end
    end,
    function(self, keep)
      local hexes = filter(
        function(h)
          return not h.feature and h.height >= 0
        end,
        keep:circle(1)
      )
      return take(mathx.random(2, 3), hexes)
    end,
    { }
  )
)
local swamp = Biomes.swamp:side() or {}
local burial = Biome.Feature.site(
  "burial",
  "items/burial.png",
  Biomes.meadows,
  function(self, hex) --weigh
    local local_burials = count(
      filter(
        function(h) return h.feature and h.feature.name == "burial" end,
        hex:in_circle(10)
      )
    )
    if local_burials > 0 or hex.height < 0 then
      return { weight = 0, feat = self }
    else
      local dist = hex:distance(Biome.Feature.center)
      local w = mathx.floor(mathx.max(0, 5 - ((dist - 15) ^ 2)))
      return { weight = w - (self.count or 0), feat = self }
    end
  end,
  function(self, hex, scenario) -- init
    self.count = (self.count or 0) + 1
  end,
  {
    Spawn:new("Skeleton", { role = "burial", side = swamp.side }),
    Spawn:new("Skeleton Archer", { role = "burial", side = swamp.side })
  }
)
function burial:description(speaker)
  return {
    portrait = speaker,
    title = "Miejsce pochówku",
    message = "To wygląda na miejsce pochówku pradawnego bohatera. Pewnie jest nawiedzone..."
  }
end
burial.side = swamp
Biomes.meadows:add_feat(burial)
Biomes.meadows:add_feat(
  Biome.Feature.neighbourhood_overlay(
    "village", 10,
    function(hex, neighbours)
      if hex.height < 0 or hex.height > 1 then
        return 0
      else
        return mathx.max(3 - neighbours, 0)
      end
    end,
    { { terrain = "Vhr", weight = 1 }, { terrain = "Vhhr", weight = 1 } }
  )
)
Biomes.meadows:add_feat(
  Biome.Feature.neighbourhood_overlay(
    "forest", 1,
    function(hex, neighbours)
      if hex.height < 0 or hex.height > 1 then
        return 0
      else
        return 100 + 2 * neighbours
      end
    end,
    { { terrain = "Fds", weight = 4 }, { terrain = "Fdf", weight = 4 },
      { terrain = "Fet", weight = 1 } }
  )
)
Biomes.meadows:add_feat(origin(Biomes.meadows))
Biomes.meadows:add_feat(Biome.Feature.none(90))

Biomes.forest.heights = {
  [-2] = "Wo",
  [-1] = "Ww",
  [0]  = "Gll",
  [1]  = "Hh",
  [2]  = "Md",
}
Biomes.forest.colour = "brown"
Biomes.forest:add_feat(
  Biome.Feature.neighbourhood_overlay(
    "forest", 1,
    function(hex, neighbours)
      if hex.height < 0 or hex.height > 1 then
        return 0
      else
        return 87 + neighbours
      end
    end,
    { { terrain = "Fp", weight = 1 } }
  )
)
Biomes.forest:add_feat(Biome.Feature.none(10))

Biomes.swamp.heights = {
  [-2] = "Ww",
  [-1] = "Ss",
  [0]  = "Ss",
  [1]  = "Sm",
  [2]  = "Hhd",
}
Biomes.swamp.colour = "black"
Biomes.swamp:add_feat(
  Biome.Feature.neighbourhood_overlay(
    "forest", 1,
    function(hex, neighbours)
      if hex.height < 0 or hex.height > 1 then
        return 0
      else
        return 30 + neighbours
      end
    end,
    {
      { terrain = "Fdw", weight = 4 },
      { terrain = "Fmw", weight = 4 },
      { terrain = "Fetd", weight = 1 }
    }
  )
)
Biomes.swamp:add_feat(
  Biome.Feature.neighbourhood_overlay(
    "village", 5,
    function(hex, neighbours)
      return mathx.max(0, 1 - neighbours)
    end,
    { { terrain = "Vhs", weight = 1 } }
  )
)
Biomes.swamp:add_feat(Biome.Feature.none(65))
Biomes.swamp.keep = "Khs"
Biomes.swamp.camp = "Chs"

Biomes.snow.heights = {
  [-2] = "Wo",
  [-1] = "Ai",
  [0]  = "Aa",
  [1]  = "Ha",
  [2]  = "Ms",
}
Biomes.snow.colour = "white"
Biomes.snow:add_feat(
  Biome.Feature.neighbourhood_overlay(
    "forest", 1,
    function(hex, neighbours)
      if hex.height < -1 or hex.height > 1 then
        return 0
      else
        return 30 + neighbours
      end
    end,
    {
      { terrain = "Fpa", weight = 3 },
      { terrain = "Fda", weight = 3 },
      { terrain = "Fma", weight = 3 },
      { terrain = "Feta", weight = 1 }
    }
  )
)
Biomes.snow:add_feat(
  Biome.Feature.neighbourhood_overlay(
    "village", 5,
    function(hex, neighbours)
      if hex.height < -1 or hex.height > 1 then
       return 0
      else
        return 2 - neighbours
      end
    end,
    { { terrain = "Voa", weight = 1 }, { terrain = "Vaa", weight = 1} }
  )
)
Biomes.snow:add_feat(Biome.Feature.none(65))
Biomes.snow.keep = "Koa"
Biomes.snow.camp = "Coa"

Biomes.desert.heights = {
  [-2] = "Wo",
  [-1] = "Ww",
  [0]  = "Dd",
  [1]  = "Hd",
  [2]  = "Mdd",
}
Biomes.desert.colour = "orange"
Biomes.desert:add_feat(
  Biome.Feature.neighbourhood_overlay(
    "forest", 1,
    function(hex, neighbours)
      if hex.height < 0 or hex.height > 1 then
        return 0
      else
        return 23 + neighbours
      end
    end,
    { { terrain = "Ftd", weight = 1 }  }
  )
)
Biomes.desert:add_feat(
  Biome.Feature.neighbourhood_overlay(
    "village", 5,
    function(hex, neighbours)
      if hex.height < 0 or hex.height > 1 then
       return 0
      else
        return 2 - neighbours
      end
    end,
    { { terrain = "Vdt", weight = 1 }, { terrain = "Vdr", weight = 1} }
  )
)
Biomes.desert:add_feat(Biome.Feature.none(75))
Biomes.desert.keep = "Kdr"
Biomes.desert.camp = "Cdr"

table.insert(Biomes, Biomes.meadows)
table.insert(Biomes, Biomes.forest)
table.insert(Biomes, Biomes.swamp)
table.insert(Biomes, Biomes.snow)
table.insert(Biomes, Biomes.desert)
table.insert(Biomes, Biomes.ocean)

return Biomes
