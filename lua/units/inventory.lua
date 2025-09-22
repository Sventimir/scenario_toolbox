Inventory = {}

Inventory.gui_wml = wml.load("~/add-ons/scenario_toolbox/gui/inventory.cfg")

function Inventory:new(items)
  return setmetatable({ contents = items }, { __index = self })
end

function Inventory:get(unit)
  local inv = self:new(unit.variables.inventory or {})
  inv.unit = unit
  return inv
end

function Inventory:consume(unit, item, quantity)
  local inv = Inventory:get(unit)
  inv:remove(item, quantity)
  inv:save()
end

function Inventory:find(item)
  return self.contents[item] or 0
end

function Inventory:add(item, quantity)
  self.contents[item] = self:find(item) + (quantity or 1)
end

function Inventory:remove(item, quantity)
  self.contents[item] = mathx.max(0, self:find(item) - (quantity or 1))
end

function Inventory:save()
  self.unit.variables.inventory = self.contents
end

function Inventory:display()
  local choice = {}
  wesnoth.sync.evaluate_single(function()
      choice.action = gui.show_dialog(
        self.gui_wml,
        function(w) return self:predisplay(w) end,
        function(w) return self:postdisplay(w, choice) end
      )
  end)
  -- execute the chosen action here
end

function Inventory:predisplay(widget)
  widget.title.label = string.format("%s - ekwipunek postaci", self.unit.name)
  for item, quantity in pairs(self.contents) do
    local entry = widget.inventory_list:add_item()
    entry.item_name.label = item
    entry.item_quantity.label = tostring(quantity)
  end
end

function Inventory:postdisplay(widget, choice)
  choice.item = widget.inventory_list.selected_index
end

Inventory.formula = {}

function Inventory.formula.has_item(name, quantity)
  return string.format("wml_vars.inventory[0].%s >= %i", name, quantity or 1)
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
end

return Inventory
