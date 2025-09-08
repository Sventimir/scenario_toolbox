local Prob = require("scenario_toolbox/lua/lib/probability")
local Vec = require("scenario_toolbox/lua/map/cubic_vector")
local Overlay = {}

function Overlay:new(props)
  return setmetatable(props or {}, { __index = self })
end

function Overlay:apply(hex)
  hex.terrain = string.format("%s^%s", hex.terrain, self.code)
  return Hex.Set:singleton(hex)
end

function Overlay.select(options, hex)
  local total = 0
  local freqs = {}
  for i, ov in ipairs(options) do
    freqs[i] = ov:weigh(hex)
    total = total + freqs[i]
  end
  if total <= 0 then
    return nil
  end
  local roll = mathx.random(0, total - 1)
  for i, freq in ipairs(freqs) do
    if roll < freqs[i] then
      return options[i]
    else
      roll = roll - freqs[i]
    end
  end
end

Overlay.none = Overlay:new({ name = "none" })

function Overlay.none:new(spec)
  return Overlay.new(self, { freq = spec.frequency })
end

function Overlay.none:weigh(hex)
  return self.freq
end

function Overlay.none:apply(hex)
  return Hex.Set:singleton(hex)
end

Overlay.forest = Overlay:new({ name = "forest" })

function Overlay.forest:new(spec)
  return Overlay.new(self, {
    base_freq = spec.frequency or 1,
    code = spec.terrain,
    freq_mult = spec.multiplier or 1,
  })
end

function Overlay.forest:weigh(hex)
  if hex.height < 0 or hex.height > 1 then
    return 0
  else
    local neighbours = filter(Hex.has_forest, hex:circle(1))
    return self.base_freq + self.freq_mult * count(neighbours)
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

function Overlay.village:weigh(hex)
  if hex.height < 0 or hex.height > 1 then
    return 0
  else
    local nearby_villages = filter(Hex.has_village, hex:in_circle(self.min_dist))
    return self.base_freq - count(nearby_villages)
  end
end

Overlay.castle = Overlay:new({ name = "castle" })

function Overlay.castle:new(spec)
  return Overlay.new(self, { 
      keep = spec.keep,
      castle = spec.castle,
      kfreq = spec.keep_frequency,
      distance = spec.distance,
      size = Prob.Normal:new(spec.mean_size, spec.size_std_dev)
  })
end

function Overlay:weigh(hex)
  local nearby_keep = any(Hex.is_keep, hex:in_circle(self.distance))
  local no_free_neighbours = all(Hex.has_overlay, hex:circle(1))
  return (nearby_keep or no_free_neighbours) and 0 or self.kfreq
end

function Overlay.castle:apply(hex)
  local castle = Hex.Set:singleton(hex)
  local neighbours = Hex.Set:new(
    hex:circle(1)):filter(function(h) return not h:has_overlay() end
  )
  local size = self.size:sample_int(1, neighbours.size)
  hex.terrain = self.keep
  for _ = 1, size do
    local h = neighbours:pop_random()
    h.terrain = self.castle
    castle:add(h)
  end
  return castle
end

Overlay.bridge = Overlay:new({ name = "bridge" })
Overlay.bridge.directions = {
  ["|"] = { Vec.unitary.n, Vec.unitary.s },
  ["/"] = { Vec.unitary.sw, Vec.unitary.ne },
  ["\\"] = { Vec.unitary.se, Vec.unitary.nw },
}

function Overlay.bridge:new(spec)
  return Overlay.new(self, {
    code = spec.code,
    freq = spec.frequency,
  })
end

function Overlay.bridge:is_land(hex)
  if not hex then
    return false
  elseif hex.biome.name == "ocean" then
    return hex.height == 2
  else
    return hex.height >= 0
  end
end

function Overlay.bridge:applicable_directions(hex)
  local applicable = {}
  for symbol, vecs in pairs(self.directions) do
    if all(function(v) return self:is_land(hex:translate(v)) end, iter(vecs)) then
      table.insert(applicable, symbol)
    end
  end
  return applicable
end

function Overlay.bridge:apply(hex)
  local applicable = self:applicable_directions(hex)
  local dir = applicable[mathx.random(#applicable)]
  hex.terrain = string.format("%s^%s%s", hex.terrain, self.code, dir)
  return Hex.Set:singleton(hex)
end

function Overlay.bridge:weigh(hex)
  local applicable = not self:is_land(hex)
    and count(filter(function(h) return not self:is_land(hex) end, hex:circle(1))) > 1
    and #self:applicable_directions(hex) > 0
  if applicable then
    return self.freq
  else
    return 0
  end
end

return Overlay
