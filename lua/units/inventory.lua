Inventory = {}
Inventory.__index = Inventory

function Inventory.new(items)
  return setmetatable({ contents = items }, Inventory)
end

function Inventory.get(unit)
  local inv = Inventory.new(unit.variables.inventory or {})
  inv.unit = unit
  return inv
end

function Inventory.consume(unit, item, quantity)
  local inv = Inventory.get(unit)
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

Inventory.filter = {}

function Inventory.filter.has_item(name)
  return wml.tag.filter_wml({
      wml.tag.variables({ 
          wml.tag.inventory({
              ["glob_on_" .. name] = "*",
              wml.tag["not"]({ [name] = 0 })
          })
      })
  })
end

return Inventory
