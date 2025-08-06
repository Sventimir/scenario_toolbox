require("scenario_toolbox/lua/lib/core")

local Spawn = {}
Spawn.__index = Spawn

if wesnoth and wesnoth.current then -- this only exists during game
  function Spawn.valid_location(hex)
    return wesnoth.map.on_board(wesnoth.current.map, hex)
      and not wesnoth.units.get(hex.x, hex.y)
  end
else
  function Spawn.valid_location(hex)
    return hex.x > 0 and hex.x <= hex.map.width and hex.y > 0 and hex.y <= hex.map.height
  end
end

function Spawn:new(unit_type, extra)
  local this = { unit_type = unit_type, extra = extra or {} }
  return setmetatable(this, self)
end

function Spawn:placement(hex, side)
  local u = { type = self.unit_type, side = side, x = hex.x, y = hex.y }
  for k, v in pairs(self.extra) do
    u[k] = v
  end
  return iter({u})
end

function Spawn:wml(hex, side)
  return map(wml.tag.unit, self:placement(hex, side))
end

function Spawn:spawn(hex, side)
  local animation = wesnoth.units.create_animator()
  local us = {}
  for desc in self:placement(hex, side) do
    local u = wesnoth.units.create(desc)
    animation:add(u, "recruited", "")
    wesnoth.units.to_map(u)
    table.insert(us, u)
  end
  if #us > 0 then
    wesnoth.interface.scroll_to_hex(hex.x, hex.y, true, false, true)
    animation:run()
  end
  return us
end

function Spawn:wolf_pack(unit_type, min_size, max_size)
   local this = Spawn:new("Wolf")
   this.min_size = min_size or 3
   this.max_size = max_size or 6

   function this:placement(hex, side)
     local hexes = Hex.Set:new(filter(Spawn.valid_location, hex:in_circle(1)))
     return repeatedly(
       function()
         if hexes.size > 0 then
           local h = hexes:pop_random()
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
    local hexes = as_table(filter(Spawn.valid_location, hex:circle(1)))
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
