local Pred = require("scenario_toolbox/lua/lib/predicate")
local Prob = require("scenario_toolbox/lua/lib/probability")
local Vec = require("scenario_toolbox/lua/map/cubic_vector")

local Overlay = {}

function Overlay:new(props)
  local ov = setmetatable(props or {}, { __index = self })
  ov.app = setmetatable({}, { __index = ov, __call = self.__call })
  return ov
end

function Overlay:selected() -- luacheck: ignore 212 (unused 'self' required by interface)
end

function Overlay:__call(terrain)
  if self.code then
    return string.format("%s^%s", terrain, self.code)
  else
    return terrain
  end
end

function Overlay:weigh(hex, map)
  local nearby_keep = any(
    function(h)
      return h:is_keep() and h:distance(hex) == self.distance
    end,
    map
  )
  local no_free_neighbours = all(
    get("overlay"),
    filter(function(h) return h:distance(hex) == 1 end, map:iter())
  )
  if not (nearby_keep or no_free_neighbours) then
      return { weight = self.kfreq, option = self.app }
  end
end

Overlay.none = Overlay:new({ name = "none" })

function Overlay.none:new(spec)
  return Overlay.new(self, { freq = spec.frequency })
end

function Overlay.none:weigh()
  return { weight = self.freq, option = self.app }
end

Overlay.forest = Overlay:new({ name = "forest" })

function Overlay.forest:new(spec)
  return Overlay.new(self, {
    base_freq = spec.frequency or 1,
    code = spec.terrain,
    freq_mult = spec.multiplier or 1,
  })
end

function Overlay.forest:weigh(hex, map)
  local height = mathx.round(hex.height)
  if  height >= 0 and height < 2 then
    local neighbours = map:filter(
      function(h)
        return h:distance(hex) == 1 and h.overlay and h.overlay.name == "forest"
      end
    )
    return {
      weight = self.base_freq + self.freq_mult * neighbours.size,
      option = self.app
    }
  end
end

Overlay.village = Overlay:new({ name = "village" })

function Overlay.village:new(spec)
  return Overlay.new(self, {
      base_freq = spec.frequency or 1,
      min_dist = spec.distance or 0,
      code = spec.terrain,
  })
end

function Overlay.village:weigh(hex, map)
  local height = mathx.round(hex.height)
  if height >= 0 and hex.height < 2 then
    local nearby_villages_score = filter_map(
      function(h)
        if h.overlay and h.overlay.name == "village" then
          return self.min_dist - h:distance(hex)
        end
      end,
      map:in_circle(hex, self.min_dist):iter()
    )
    return {
      weight = self.base_freq - fold(arith.add, 0, nearby_villages_score),
      option = self.app
    }
  end
end

Overlay.castle = Overlay:new({ name = "castle" })

function Overlay.castle:new(spec)
  return Overlay.new(self, {
      keep = setmetatable({ name = "keep", code = spec.keep }, { __index = self }),
      castle = setmetatable({ name = "castle", code = spec.castle }, { __index = self }),
      kfreq = spec.keep_frequency,
      distance = spec.distance,
      size = Prob.Normal:new(spec.mean_size, spec.size_std_dev)
  })
end

function Overlay.castle:__call()
  return self.code
end

function Overlay.castle:selected()
  if self.keep then
    self.keep.size = self.keep.size - 1
  end
end

function Overlay.castle:weigh(hex, map)
  local neighbourhood = map:in_circle(hex, self.distance)
  local sites_in_range = neighbourhood:filter(Pred:has("site"))
  local keeps_in_range = neighbourhood:filter(Pred:has("overlay", "keep"))
  local neighbours = keeps_in_range:intersect(map:circle(hex, 1))
  local blockers = keeps_in_range:union(sites_in_range)
  local keep = neighbours.size > 0 and neighbours:pop_random()
  local free_neighbours = 6 - map:circle(hex, 1).size
  if keep and keep.overlay.size > 0 then
    return {
      weight = 1000000,
      option = setmetatable({ keep = keep.overlay }, { __index = self.castle, __call = self.__call })
    }
  elseif blockers.size == 0 and mathx.round(hex.height) >= 0 and free_neighbours > 0 then
    return {
      weight = self.kfreq,
      option = setmetatable(
        { size = self.size:sample_int(1, free_neighbours) },
        { __index = self.keep, __call = self.__call }
      )
    }
  end
end

Overlay.bridge = Overlay:new({ name = "bridge" })
Overlay.bridge.directions = {
  ["|"] = { Vec.unitary.n, Vec.unitary.s },
  ["/"] = { Vec.unitary.sw, Vec.unitary.ne },
  ["\\"] = { Vec.unitary.se, Vec.unitary.nw },
}

function Overlay.bridge.is_water(hex)
  local t = hex:terrain()
  return string.find(t, "^W") or string.find(t, "^Ss")
end

function Overlay.bridge:new(spec)
  local b = Overlay.new(self, {
    code = spec.code,
    freq = spec.frequency,
  })
  function b.app(dir)
    return setmetatable({ dir = dir }, { __index = b, __call = self.__call })
  end
  return b
end

function Overlay.bridge:__call(terrain)
  return string.format("%s^%s%s", terrain, self.code, self.dir)
end

-- function Overlay.bridge:applicable_directions(hex)
--   local applicable = {}
--   for symbol, vecs in pairs(self.directions) do
--     if all(function(v) return self:is_land(hex:translate(v)) end, iter(vecs)) then
--       table.insert(applicable, symbol)
--     end
--   end
--   return applicable
-- end

function Overlay.bridge:weigh(hex)
end

return Overlay
