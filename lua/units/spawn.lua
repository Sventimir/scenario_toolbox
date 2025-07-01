require("scenario_toolbox/lua/lib/core")
local WML = require("scenario_toolbox/lua/wml/wml")

local Spawn = {}
Spawn.__index = Spawn

function Spawn:new(unit_type)
  local this = { unit_type = unit_type }
  return setmetatable(this, self)
end

function Spawn:place(hex)
  return WML:tag("unit", { type = self.unit_type, x = hex.x, y = hex.y })
end

function Spawn:wolf_pack(unit_type, min_size, max_size)
   local this = Spawn:new("Wolf")
   this.min_size = min_size or 3
   this.max_size = max_size or 6

   function this:place(hex)
     local size = mathx.random(self.min_size, self.max_size)
     local units = WML:new()
     local hexes = as_table(chain(iter({ hex }), hex:circle(1)))
     for i = 1, size do
       local h = table.remove(hexes, mathx.random(#hexes))
       units:insert("unit", { type = self.unit_type, x = h.x, y = h.y })
     end
     return units
   end

   return this
end

function Spawn:family(parent_type, child_type, min_size, max_size)
  local this = Spawn:new(parent_type)
  this.child_type = child_type
  this.min_size = min_size or 1
  this.max_size = max_size or 6

  function this:place(hex)
    local size = mathx.random(self.min_size, self.max_size)
    local units = Spawn.place(self, hex)
    local hexes = as_table(hex:circle(1))

    for i = 1, size do
      local h = table.remove(hexes, mathx.random(#hexes))
      units:insert("unit", { type = self.child_type, x = h.x, y = h.y })
    end

    return units
  end

  return this
end

return Spawn
