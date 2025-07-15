Biome = require("scenario_toolbox/lua/map/biome")
Spawn = require("scenario_toolbox/lua/units/spawn")


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
  passive = { 
    Spawn:family("Woodland Boar", "Piglet", 2, 4),
    Spawn:new("Raven"),
    Spawn:new("Giant Rat"),
    Spawn:new("Bay Horse"),
  },
  active = {
    Spawn:wolf_pack("Wolf", 1, 2),
  },
  boss = Spawn:new("Great Wolf", {
                     max_hitpoints = 90,
                     name = "Imiędoustalenia",
                     id = "meadows-boss",
  })
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


return {
  meadows = Meadows,
  forest = Forest,
  swamp = Swamp,
  snow = Snow,
  desert = Desert
}
