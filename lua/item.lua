local Inventory = require("scenario_toolbox/lua/units/inventory")

Item = {}
Item.__index = Item

function Item:new(name, img)
  local i = { name = name, img = img, __drops = 0 }
  return setmetatable(i, self)
end

function Item:drop(unit, for_sides)
  local id = self.__drops
  local loc = { x = unit.x, y = unit.y }
  local event_id = string.format("%s_pickup_%i", self.name, id)
  local event_filter = { x = loc.x, y = loc.y }
  if for_sides then
    event_filter.side = for_sides
  end
  self.__drops = self.__drops + 1
  wesnoth.wml_actions.item({
      name = self.name,
      x = unit.x,
      y = unit.y,
      image = self.img,
      wml.tag.contents(self.contents or { [self.name] = 1 })
  })
  wesnoth.game_events.add({
      id = event_id,
      name = "moveto",
      first_time_only = false,
      filter = { wml.tag.filter(event_filter) },
      content = {
        wml.tag.inventory({
            wml.tag.filter(loc),
            action = "add",
            item = "bones"
        }),
        wml.tag.remove_item(loc),
        wml.tag.remove_event({ id = event_id }),
      }
  })
end

Item.bones = Item:new("bones", "items/bones.png")

return Item
