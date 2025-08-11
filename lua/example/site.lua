Hex = require("scenario_toolbox/lua/map/hex")
Prob = require("scenario_toolbox/lua/lib/probability")

local Site = {}
Site.Map = {}

function Site:new()
  return setmetatable({ variables = {} }, { __index = self })
end

function Site:wml(x, y)
  local spec = {
    name = self.name,
    image = self.image,
    visible_in_fog = true,
    wml.tag.variables(self.variables),
  }
  if y then
    spec.x = x
    spec.y = y
  else
    spec.x = x.x
    spec.y = x.y
  end
  return { wml.tag.item(spec) }
end

Site.origin = { name = "origin", image = "items/altar.png" }
setmetatable(Site.origin, { __index = Site })

function Site.origin:new()
  local s = Site.new(self, "origin", "items/altar.png")
  s.variables.title = "Ołtarz Baziola"
  s.variables.description = "Na tym ołtarzu Praojciec Baziol przyjmuje ofiary z pokonanych przedwiecznych. "
    .. "Obecnie naszym celem jest Shazza, której szukać należy na łąkach."
  return s
end

function Site.origin:wml(x, y)
  local location = { x = y and x or x.x, y = y or x.y }
  local spec = Site.wml(self, location)
  local lua_code = [[
    local opening_dialogue = require("scenario_toolbox/lua/example/dialogues/opening")
    local d = opening_dialogue({ x = %i, y = %i})
    d:play()
  ]]
  local dialogue = wml.tag.event({
      name = "start",
      wml.tag.lua({ code = string.format(lua_code, location.x, location.y) })      
  })
  table.insert(spec, dialogue)
  return spec
end

Site.altar = {
  name = "altar",
  image = "items/altar-evil.png",
}
setmetatable(Site.altar, { __index = Site })

function Site.altar:new(spec)
  local alt = Site.new(self)
  alt.variables.title = "Ołtarz Przedwiecznego"
  alt.variables.description = spec.description

  local dist = wml.get_child(spec, "distance_from_origin")
  alt.distance = Prob.Normal:new(dist.mean, dist.standard_deviation)
  alt.min_dist = dist.minimum or 1
  alt.max_dist = dist.maximum or mathx.huge
  return alt
end

function Site.altar:place(origin, available_hexes)
  local r = self.distance:sample_int(self.min_dist, self.max_dist)
  local hexset = Hex.Set:new(origin:circle(r)):intersect(
    available_hexes:filter(function(h) return h.height >= 0 end)
  )
  local i = 0
  while hexset:empty() and r + i <= self.max_dist and r - i >= self.min_dist do
    i = i + 1
    hexset = Hex.Set:new(chain(origin:circle(r + i), origin:circle(r - i)))
    hexset = hexset:intersect(available_hexes)
  end
  if hexset:empty() then
    error("No valid locations for altar!")
  end
  return self:wml(hexset:random())
end

function Site:init(cfg)
  self.Map.width = cfg.width
  self.Map.height = cfg.height
end

return Site
