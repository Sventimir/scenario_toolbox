local Site = {}

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

Site.altar = { name = "altar", image = "items/altar-evil.png"}
setmetatable(Site.altar, { __index = Site })

function Site.altar:new(spec)
  local alt = Site.new(self)
  s.variables.title = "Ołtarz Przedwiecznego"
  s.variables.description = spec.description

  local dist = wml.get_child(spec, "distance_from_origin")
  alt.mean_dist = dist.mean
  alt.dist_std_dev = dist.standard_deviation
  return alt
end

-- normal distribution
function Site.Altar:origin_distance_distribution(x)
  local factor = 1 / sqrt(2 * mathx.pi * (self.dist_std_dev ^ 2))
  local exponent = ((x - self.mean_dist) ^ 2) / (2 * (self.dist_std_dev ^ 2))
  return factor * (mathx.exp(1) ^ exponent)
end

function Site.Altar:place(origin, available_hexes)
  
end

return Site
