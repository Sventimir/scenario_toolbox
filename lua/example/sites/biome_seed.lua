local Hex = require("scenario_toolbox/lua/map/hex")
local Prob = require("scenario_toolbox/lua/lib/probability")

local Seed = {}
local __Seed = { __index = Seed }

function Seed.new(biome, spec)
  local this = {
    biome = biome,
    count = spec.count,
    distance = Prob.Normal:from_wml(wml.get_child(spec, "distance_from_origin"))
  }
  return setmetatable(this, __Seed)
end

Seed.Hex = setmetatable({}, Hex.__Gen)
local __Hex = { __index = Seed.Hex }

function Seed.Hex.new(x, y)
  return setmetatable(Hex.Gen.new(x, y), __Hex)
end

function Seed.Hex:gen_biome()
  return self.seed
end

function Seed.Hex:propagate() -- luacheck: ignore 212 (unused 'self' required by interface)
  return { option = Hex.Gen, weight = 1 }
end

function Seed:place(map_hexset, frontier)
  if not map_hexset.index.seeds then
    map_hexset:add_index("seeds", function(h) return h.seed end)
  end
  local excluded = Hex.Set:new(
    chain(
      join(map(function (s) return s:in_circle(5) end, map_hexset.index.sites:iter())),
      join(map(function (s) return s:in_circle(5) end, map_hexset.index.seeds:iter()))
    )
  )

  for _ = 1, self.count do
    local r = self.distance:sample_int()
    local origin = map_hexset.index.origin[1]
    local hexes = Hex.Set:new(origin:circle(r)):diff(excluded)
    if hexes.size > 0 then
      local hex = self.Hex.new(hexes:random())
      hex.seed = self.biome
      hex:generate(map_hexset)
      map_hexset:add(hex)
      excluded = excluded:union(Hex.Set:new(hex:in_circle(10)))
      for h in hex:circle(1) do
        frontier:add(h)
      end
    end
  end
end

return Seed
