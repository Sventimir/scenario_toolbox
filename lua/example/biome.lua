local Hex = require("scenario_toolbox/lua/map/hex")
local Overlay = require("scenario_toolbox/lua/map/overlay")

local Biome = {}
Biome.__index = Biome

function Biome:new(spec)
  local terrain = wml.get_child(spec, "terrain")
  local biome = {
    name = spec.name,
    color = spec.color,
    terrain = {
      [-2] = terrain.deep,
      [-1] = terrain.shallow,
      [0]  = terrain.plain,
      [1]  = terrain.hills,
      [2]  = terrain.mountains,
    },
    overlay = {},
    sites = {},
    hexes = Hex.Set:new(),
  }

  for ov in wml.child_range(spec, "overlay") do
    table.insert(biome.overlay, Overlay[ov.type]:new(ov))
  end

  for site in wml.child_range(spec, "site") do
    table.insert(biome.sites, Site[site.type]:new(site))
  end

  return setmetatable(biome, self)
end

function Biome:add_hex(hex)
  if hex.biome then
    hex.biome:remove_hex(hex)
  end
  hex.biome = self
  self.hexes:add(hex)
end

function Biome:remove_hex(hex)
  self.hexes:remove(hex)
end

function Biome:belongs(hex)
  return self.hexes:member(hex)
end

function Biome:time_area(it, state)
  local area = { id = self.name, x = "", y = "" }
  for hex in self.hexes:iter() do
    area.x = string.format("%s%i,", area.x, hex.x)
    area.y = string.format("%s%i,", area.y, hex.y)
  end
  for time in it, state do
    table.insert(area, wml.tag.time(time))
  end
  return area
end

return Biome
