Hex = require("scenario_toolbox/lua/map/hex")
Prob = require("scenario_toolbox/lua/lib/probability")

local Site = {}
Site.Map = {}

function Site:new()
  return setmetatable({ variables = {} }, { __index = self })
end

function Site:init(cfg)
  self.Map.width = cfg.width
  self.Map.height = cfg.height
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
  alt.variables.title = "Ołtarz Przedwiecznego"
  alt.variables.description = spec.description

  local dist = wml.get_child(spec, "distance_from_origin")
  alt.mean_dist = dist.mean
  alt.dist_std_dev = dist.standard_deviation
  alt.max_radius = mathx.min(self.Map.width, self.Map.height) - 3
  return alt
end

-- We want to generate the altar at a radius from origin, where the
-- radius is distributed normally over the island's surface.  We need
-- a cumulative normal distribution here as well as its inverse.  We
-- need the distribution itself to convert minimum and maximum radius
-- to their probabilities, to obtain the range from which we need to
-- sample a random value. Then we use the inverse function to
-- transform the random value back into a radius.
-- This is a heavy calculation though, so it might be easier to use a
-- quadratic function instead of normal distribution, which for our
-- purpose should give a good enough approximation with far simpler
-- calculations. However, in that case, instead of a regular quadratic
-- function we need a cumulative variant of it, such that it is a
-- bijection (which regular quadratic function isn't).
function Site.altar:origin_distance_distribution(x)
  local factor = 1 / sqrt(2 * mathx.pi * (self.dist_std_dev ^ 2))
  local exponent = ((x - self.mean_dist) ^ 2) / (2 * (self.dist_std_dev ^ 2))
  return factor * (mathx.exp(1) ^ exponent)
end

function Site.altar:place(origin, available_hexes)
  local r = Prob.Mock:sample(10, self.max_radius)
  local hexset = Hex.Set:new(origin:circle(r)):intersect(
    available_hexes:filter(function(h) return h.height >= 0 end)
  )
  local i = 0
  while hexset:empty() and i < r do
    i = i + 1
    hexset = Hex.Set:new(chain(origin:circle(r + i), origin:circle(r - i)))
    hexset = hexset:intersect(available_hexes)
  end
  return self:wml(hexset:random())
end

return Site
