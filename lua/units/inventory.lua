Inventory = {}

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

Inventory.formula = {}

function Inventory.formula.has_item(name, quantity)
  return string.format("wml_vars.inventory[0].%s >= %i", name, quantity or 1)
end

if wesnoth.wml_actions then -- only available at runtime
  function wesnoth.wml_actions.inventory(conf)
    local f = wml.get_child(conf, "filter")
    for u in iter(wesnoth.units.find_on_map(f)) do
      local inv = Inventory:get(u)
      inv[conf.action](inv, conf.item, conf.quantity)
      inv:save()
    end
  end
end

return Inventory
