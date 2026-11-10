local Hex = require("scenario_toolbox/lua/map/hex")

local Origin = { name = "origin", starting_locations = {} }
local __Origin = { __index = Origin }

Origin.Hex = setmetatable({ image = "items/altar.png" }, Hex.__Gen)
Origin.__Hex = { __index = Origin.Hex }

function Origin.Hex.new(x, y)
  return setmetatable(Hex.Gen.new(x, y), Origin.__Hex)
end

function Origin.Hex:generate(_)
  self.height = 0
end

function Origin.Hex:propagate() -- luacheck: ignore 212 (unused 'self' required by the interface)
  return { weight = 1000, option = Origin.StartingLocation }
end

function Origin.new(biome)
  local this = { biome = biome }
  return setmetatable(this, __Origin)
end

function Origin.Hex:wml()
  return {
    wml.tag.item({
        x = self.x,
        y = self.y,
        name = "origin",
        image = self.image,
        visible_in_fog = true,
        wml.tag.variables({
            title = "Ołtarz Baziola",
            description = "Na tym ołtarzu Praojciec Baziol przyjmuje ofiary z pokonanych przedwiecznych. "
              .. "Obecnie naszym celem jest Shazza, której szukać należy na łąkach."
        })
    }),
    wml.tag.event({
        name = "start",
        wml.tag.dialogue({
            filename = "scenario_toolbox/lua/example/dialogues/opening",
            x = self.x,
            y = self.y
        })
    })
  }
end

function Origin:place(map, frontier)
  local origin = self.Hex.new(map.width / 2, map.height / 2)
  origin.biome = self.biome
  origin.site = self.name
  origin:generate(self.biome)
  map:add(origin)
  map:add_index("origin", { origin })
  map:add_index("sites", function(h) return h.site end)
  for hex in origin:circle(1) do
    frontier:add(hex)
  end
end


Origin.StartingLocation = setmetatable({}, Hex.__Gen)
local __StartingLoc = { __index = Origin.StartingLocation }

function Origin.StartingLocation.new(x, y)
  local this = setmetatable(Hex.Gen.new(x, y), __StartingLoc)
  if #Origin.starting_locations > 0 then
    this.starting_location = table.remove(Origin.starting_locations, 1)
  end
  return this
end

function Origin.StartingLocation:propagate() -- luacheck: ignore 212 (unused 'self' required by the interface)
  return { weight = 1, option = Hex.Gen }
end

return Origin
