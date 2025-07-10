require("scenario_toolbox/lua/lib/core")
local WML = require("scenario_toolbox/lua/wml/wml")

local Spawn = {}
Spawn.__index = Spawn

function Spawn:new(unit_type)
  local this = { unit_type = unit_type }
  return setmetatable(this, self)
end

function Spawn:placement(hex, side)
  return iter({ { type = self.unit_type, side = side, x = hex.x, y = hex.y } })
end

function Spawn:wml(hex, side)
  return WML:new(
    as_table(
      map(
        function(t)
          return WML:tag("unit", t)
        end,
        self:placement(hex, side)
      )
    )
  )
end

function Spawn:spawn(hex, side)
  local animation = wesnoth.units.create_animator()
  for desc in self:placement(hex, side) do
    local u = wesnoth.units.create(desc)
    animation:add(u, "recruited", "")
    wesnoth.units.to_map(u)
  end
  wesnoth.interface.scroll_to_hex(hex.x, hex.y, true, false, true)
  animation:run()
end

function Spawn:wolf_pack(unit_type, min_size, max_size)
   local this = Spawn:new("Wolf")
   this.min_size = min_size or 3
   this.max_size = max_size or 6

   function this:placement(hex, side)
     local hexes = as_table(chain(iter({ hex }), hex:circle(1)))
     return repeatedly(
       function()
         if #hexes > 0 then
           local h = table.remove(hexes, mathx.random(#hexes))
           return { type = self.unit_type, side = side, x = h.x, y = h.y }
         else
           return nil
         end
       end,
       mathx.random(self.min_size, self.max_size)
     )
   end

   return this
end

function Spawn:family(parent_type, child_type, min_size, max_size)
  local this = Spawn:new(parent_type)
  this.child_type = child_type
  this.min_size = min_size or 1
  this.max_size = max_size or 6

  function this:placement(hex, side)
    local hexes = as_table(hex:circle(1))
    return chain(
      Spawn.placement(self, hex, side),
      repeatedly(
        function()
          if #hexes > 0 then
            local h = table.remove(hexes, mathx.random(#hexes))
            return { type = self.child_type, side = side, x = h.x, y = h.y }
          else
            return nil
          end
        end,
        mathx.random(self.min_size, self.max_size)
      )
    )
  end

  return this
end

return Spawn
