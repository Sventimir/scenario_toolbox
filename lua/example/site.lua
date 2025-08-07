local Site = {}

function Site:new(name, image)
  return setmetatable({ name = name, image = image, variables = {} }, { __index = self })
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

Site.Origin = setmetatable({}, { __index = Site })

function Site.Origin:new()
  local s = Site.new(self, "origin", "items/altar.png")
  s.variables.title = "Ołtarz Baziola"
  s.variables.description = "Na tym ołtarzu Praojciec Baziol przyjmuje ofiary z pokonanych przedwiecznych. "
    .. "Obecnie naszym celem jest Shazza, której szukać należy na łąkach."
  return s
end

function Site.Origin:wml(x, y)
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

return Site
