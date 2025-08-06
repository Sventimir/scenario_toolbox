local Overlay = {}

function Overlay:new(props)
  return setmetatable(props or {}, { __index = self })
end

function Overlay:apply(hex)
  hex.terrain = string.format("%s^%s", hex.terrain, self.code)
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

function Overlay.none:apply()
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
      cfreq = spec.castle_frequency,
      distance = spec.distance,
  })
end

function Overlay:weigh(hex)
  local adjacent_keep = any(Hex.is_keep, hex:circle(1))
  if adjacent_keep and adjacent_keep.biome.name == hex.biome.name then
    local castle_size = count(filter(Hex.is_castle, adjacent_keep:circle(1)))
    if castle_size > 0 then
      return mathx.round(self.cfreq / mathx.max(1, castle_size))
    else
      return self.cfreq ^ 3
    end
  else
    local nearby_keep = any(Hex.is_keep, hex:in_circle(self.distance))
    return nearby_keep and 0 or self.kfreq
  end
end

function Overlay.castle:apply(hex)
  local adjacent_keep = any(Hex.is_keep, hex:circle(1))
  if adjacent_keep then
    hex.terrain = self.castle
  else
    hex.terrain = self.keep
  end
end

return Overlay
