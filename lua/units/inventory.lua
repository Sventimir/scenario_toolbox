local Hex = require("scenario_toolbox/lua/map/hex")

local Inventory = {}

Inventory.gui_wml = wml.load("~/add-ons/scenario_toolbox/gui/inventory.cfg")

function Inventory:new(items)
  local inv = setmetatable({ contents = {} }, { __index = self })
  for i in iter(items) do
    inv:add(i)
  end
  return inv
end

function Inventory:get(unit)
  local inv = self:new(wml.child_array(unit.variables.inventory or {}, "item"))
  inv.unit = unit
  return inv
end

function Inventory:find(item)
  if type(item) == "string" then
    return self.contents[item]
  else
    return self.contents[item.name]
  end
end

function Inventory:add(item)
  self.contents[item.name] = self.Item:new(item)
end

function Inventory:quantity(item)
  local i = self:find(item)
  return i:with_quantity()
end

function Inventory:remove(item, quantity)
  local i = self:find(item)
  local qty = i:with_quantity(-(quantity or 1))
  if qty == 0 then
    self.contents[i.name] = nil
  end
  return qty
end

function Inventory:save()
  local inv = {}
  for item in self:iter() do
    -- if item was picked up from the map, it has a location - we need to remove it.
    item.x = nil
    item.y = nil
    table.insert(inv, item)
  end
    wml.array_access.set("inventory.item", inv, self.unit)
end

-- For synchronization's sake it is important that the order of iteration is consistent
function Inventory:iter()
  local ids = {}
  for id, _ in pairs(self.contents) do
    table.insert(ids, id)
  end
  table.sort(ids)
  return map(function(id) return self.contents[id] end, iter(ids))
end

function Inventory:display()
  local choice = { choices = {} }
  wesnoth.sync.evaluate_single(function()
      choice.action = gui.show_dialog(
        self.gui_wml,
        function(w) return self:predisplay(w, choice) end,
        function(w) return self:postdisplay(w, choice) end
      )
  end)
  if self.actions[choice.action] and choice.item then
    self.actions[choice.action](self, choice.item)
  end
end

function Inventory:predisplay(widget, choice)
  widget.title.label = string.format("%s - ekwipunek postaci", self.unit.name)
  for item in self:iter() do
    local entry = widget.inventory_list:add_item()
    table.insert(choice.choices, item)
    entry.item_name.label = item.display
    entry.item_quantity.label = tostring(item:with_quantity())
  end
end

function Inventory:postdisplay(widget, choice)
  choice.item = choice.choices[widget.inventory_list.selected_index]
end

Inventory.actions = {
  [1] = function(self, item) end,
  [2] = function(self, item)
    item:place(self.unit)
    self:remove(item)
  end,
}

Inventory.formula = {}

function Inventory.formula.has_item(name, quantity)
  return string.format(
    "find(wml_vars.inventory[0].item, name = '%s').(quantity or 1) >= %i",
    name,
    quantity or 1
  )
end

Inventory.Item = {
  wml_props = {
    x = true,
    y = true,
    image = true,
    halo = true,
    name = true,
    team_name = true,
    visible_in_fog = true,
    submerge= true,
    z_order = true,
    redraw = true
  }
}

function Inventory.Item:new(spec)
  return setmetatable(spec, { __index = self })
end

function Inventory.Item:from_map(x, y)
  local loc = wesnoth.map.read_location(x, y)
  return filter_map(
    function(i)
      if i.name and string.find(i.name, "^inventory%.") then
        local vars = i.variables
        i.variables = nil
        local spec = wml.merge(wml.literal(i), vars, "append")
        return self:new(spec)
      end
    end,
    iter(wesnoth.interface.get_items(loc.x, loc.y))
  )
end

function Inventory.Item:map_wml()
  local vars = {}
  local spec = {}
  for prop, value in pairs(self) do
    if self.wml_props[prop] then
      spec[prop] = value
    else
      vars[prop] = value
    end
  end
  local filter_team = wml.get_child(self, "fitler_team")
  if filter_team then
    table.insert(sepc, wml.tag.filter_team(filter_team))
  end
  table.insert(spec, wml.tag.variables(vars))
  return spec
end

function Inventory.Item:with_quantity(increment)
  self.quantity = (self.quantity or 1) + (increment or 0)
  if self.quantity < 0 then
    error("Cannot decrease item's quantity - not enough!")
  else
    return self.quantity
  end
end

function Inventory.Item:place(x, y)
  local loc = wesnoth.map.read_location(x, y)
  wesnoth.wml_actions.item(wml.merge(self:map_wml(), loc))
end

if wesnoth.wml_actions then -- only available at runtime
  function wesnoth.wml_actions.inventory(conf)
    local f = wml.get_child(conf, "filter")
    for u in iter(wesnoth.units.find_on_map(f)) do
      local inv = Inventory:get(u)
      for action in iter(conf) do -- these are WML subtags
        if inv[action[1]] then
          inv[action[1]](inv, action[2].item, action[2].quantity)
        end
      end
      inv:save()
      if conf.show then
        inv:display()
      end
    end
  end
end

if wesnoth.game_events then -- only available at runtime
  wesnoth.game_events.add({
      name = "prestart",
      id = "inventory_menu_setup",
      content = {
        wml.tag.set_menu_item({
            id = "inventory_menu",
            description = "Ekwipunek",
            image = "backpack-menu.png",
            wml.tag.default_hotkey({ key = "i" }),
            wml.tag.filter_location({
                wml.tag.filter({ side = "$side_number" })
            }),
            wml.tag.command({
                wml.tag.inventory({
                    wml.tag.filter({ x = "$x1", y = "$y1" }),
                    show = true
                })
            })
        })
      }
  })

  wesnoth.game_events.add({
      name = "die",
      id = "inventory-drop",
      first_time_only = false,
      filter = { wml.tag.filter({}) }, -- all units
      action = function()
        -- NOTE that wml.variables.unit does not contain variables.
        local inv = Inventory:get(wesnoth.units.find({ id = wml.variables.unit.id })[1])
        for item in inv:iter() do
          item:place(inv.unit)
        end
      end
  })

  wesnoth.game_events.add_repeating(
    "moveto",
    function()
      local loc = wesnoth.map.read_location(wml.variables.x1, wml.variables.y1)
      local inv = Inventory:get(wesnoth.units.find(loc)[1])
      local anything = false
      for it in Inventory.Item:from_map(loc) do
        anything = true
        inv:add(it)
      end
      if anything then
        inv:save()
        wesnoth.wml_actions.remove_item(loc)
        inv:display()
      end
    end,
    10
  )
end

return Inventory
