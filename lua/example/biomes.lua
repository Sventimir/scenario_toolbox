Biome = require("scenario_toolbox/lua/map/biome")
Spawn = require("scenario_toolbox/lua/units/spawn")


Ocean = Biome:new("ocean", 1)
Ocean.heights = {
  [-2] = "Wo",
  [-1] = "Ww",
  [0]  = "Wwr",
}

Meadows = Biome:new("meadows", 100)
Meadows.heights = {
  [-2] = "Wo",
  [-1] = "Ww",
  [0]  = "Gg",
  [1]  = "Hh",
  [2]  = "Mm",
}
Meadows:add_feat(
  Biome.Feature.neighbourhood_overlay(
    "forest", 1,
    function(hex, neighbours)
      if hex.height < 0 or hex.height > 1 then
        return 0
      else
        return 50 + 2 * neighbours
      end
    end,
    { { terrain = "Fds", weight = 4 }, { terrain = "Fdf", weight = 4 },
      { terrain = "Fet", weight = 1 } }
  )
)
Meadows:add_feat(
  Biome.Feature.neighbourhood_overlay(
    "village", 5,
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
Meadows.keep = "Ker"
Meadows.camp = "Cer"
Meadows.spawn = {
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
                     name = "Imiędoustalenia",
                     id = "meadows-boss",
  })
}

Forest = Biome:new("forest", 100)
Forest.heights = {
  [-2] = "Wo",
  [-1] = "Ww",
  [0]  = "Gll",
  [1]  = "Hh",
  [2]  = "Md",
}
Forest:add_feat(
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
Forest.keep = "Kv"
Forest.camp = "Cv"

Swamp = Biome:new("swamp", 100)
Swamp.heights = {
  [-2] = "Ww",
  [-1] = "Ss",
  [0]  = "Ss",
  [1]  = "Sm",
  [2]  = "Hhd",
}
Swamp:add_feat(
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
Swamp:add_feat(
  Biome.Feature.neighbourhood_overlay(
    "village", 5,
    function(hex, neighbours)
      return mathx.max(0, 1 - neighbours)
    end,
    { { terrain = "Vhs", weight = 1 } }
  )
)
Swamp.keep = "Khs"
Swamp.camp = "Chs"

Snow = Biome:new("snow", 100)
Snow.heights = {
  [-2] = "Wo",
  [-1] = "Ai",
  [0]  = "Aa",
  [1]  = "Ha",
  [2]  = "Ms",
}
Snow:add_feat(
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
Snow:add_feat(
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
Snow.keep = "Koa"
Snow.camp = "Coa"

Desert = Biome:new("desert", 100)
Desert.heights = {
  [-2] = "Wo",
  [-1] = "Ww",
  [0]  = "Dd",
  [1]  = "Hd",
  [2]  = "Mdd",
}
Desert:add_feat(
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
Desert:add_feat(
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
Desert.keep = "Kdr"
Desert.camp = "Cdr"


return {
  meadows = Meadows,
  forest = Forest,
  swamp = Swamp,
  snow = Snow,
  desert = Desert,
  Meadows,
  Forest,
  Swamp,
  Snow,
  Desert,
}
