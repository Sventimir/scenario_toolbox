local WML = require("scenario_toolbox/lua/wml/wml")

local Item = {}
Item.__index = Item

function Item:new(name, hex, props)
  local this = {
    hex = hex,
    name = name,
    image = props.image,
    halo = props.halo,
    visible_in_fog = props.visible_in_fog,
    team_name = props.team_name,
  }
  return setmetatable(this, self)
end

function Item:wml()
  return {
      x = self.hex.x,
      y = self.hex.y,
      name = self.name,
      image = self.image,
      halo = self.halo,
      visible_in_fog = self.visible_in_fog,
      team_name = self.team_name,
  }
end

return Item
