Biome = require("scenario_toolbox/lua/map/biome")
Spawn = require("scenario_toolbox/lua/units/spawn")


local Altar = Biome.Feature.building(
  "altar",
  "items/altar-evil.png",
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
  end
)

function Altar:assign(hex)
  hex.feature = self
  hex.biome.features:remove(self.name)
end

function Altar:apply(hex, scenario)
  local item = {
      x = hex.x,
      y = hex.y,
      name = "altar-" .. hex.biome.name,
      image = "items/altar-evil.png",
      visible_in_fog = true,
  }
  table.insert(scenario, wml.tag.item(item))
  hex.biome.altar = hex
end

Ocean = Biome:new("ocean", 1)
Ocean.heights = {
  [-2] = "Wo",
  [-1] = "Ww",
  [0]  = "Wwr",
}
Ocean.colour = "teal"

Meadows = Biome:new("meadows", 200)
Meadows.heights = {
  [-2] = "Wo",
  [-1] = "Ww",
  [0]  = "Gg",
  [1]  = "Hh",
  [2]  = "Mm",
}
Meadows.colour = "green"
Meadows:add_feat(Altar)
Meadows:add_feat(
  Biome.Feature.castle(
    "Ker", "Cer",
    function(feat, hex)
      local center_dist = hex:distance(Biome.Feature.center)
      if center_dist == 3 then
        return { weight = feat.central_camp and 0 or 100, feat = feat }
      elseif hex.height < 0 or center_dist < 7 then
        return { weight = 0, feat = feat }
      else
        return { weight = 1, feat = feat }
      end
    end,
    function(self, keep)
      if keep:distance(Biome.Feature.center) == 3 then
        self.central_camp = true
      end
      local hexes = filter(
        function(h)
          return not h.feature and h.height >= 0
        end,
        keep:circle(1)
      )
      return take(mathx.random(2, 3), hexes)
    end,
    { central_camp = false }
  )
)
-- Meadows:add_feat(
--   Biome.Feature.building(
--     "burial",
--     "items/burial.png",
--     function(self, hex) --weigh
--       if hex.height < 0 then
--         return { weight = 0, feat = self }
--       else
--         local dist = hex:distance(Biome.Feature.center)
--         local w = mathx.floor(mathx.max(0, 5 - ((dist - 15) ^ 2)))
--         return { weight = w - (self.count or 0), feat = self }
--       end
--     end,
--     function(self, hex, scenario) -- init
--       self.count = (self.count or 0) + 1
--       local s = wml.find_child(scenario, "side", { wml.tag.variables({ biome = "meadows" }) })
--       local vars = wml.get_child(s, "variables")
--       table.insert(vars, wml.tag.burial({ x = hex.x, y = hex.y }))
--     end
--   )
-- )
Meadows:add_feat(
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
Meadows:add_feat(
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
Forest.colour = "brown"
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
Swamp.colour = "black"
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
Snow.colour = "white"
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
Desert.colour = "orange"
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
