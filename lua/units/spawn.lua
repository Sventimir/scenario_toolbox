require("scenario_toolbox/lua/lib/core")
local Hex = require("scenario_toolbox/lua/map/hex")

local Spawn = {}

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

function Spawn:from_spec(spec)
  if spec.type then
    return self[spec.type]:new(spec)
  else
    return self:new(spec)
  end
end

function Spawn:new(unit)
  return setmetatable(unit, { __index = self })
end

function Spawn:placement(hex, side)
  local u = wml.clone(wml.get_child(self, "unit"))
  u.x = hex.x
  u.y = hex.y
  if not u.side then u.side = side end
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
    u.x, u.y = wesnoth.paths.find_vacant_hex(hex.x, hex.y, u)
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

Spawn.wolf_pack = setmetatable({}, { __index = Spawn })

function Spawn.wolf_pack:new(spec)
  local s = { min_size = spec.min_size, max_size = spec.max_size }
  s.unit = wml.get_child(spec, "unit")
  return setmetatable(s, { __index = self })
end

function Spawn.wolf_pack:placement(hex, side)
  local hexes = Hex.Set:new(filter(Spawn.valid_location, hex:in_circle(1)))
  return repeatedly(
    function()
      if hexes.size > 0 then
        local h = hexes:pop_random()
        local u = wml.clone(wml.literal(self.unit))
        u.x = h.x
        u.y = h.y
        if side then u.side = side end
        return u
      else
        return nil
      end
    end,
    mathx.random(self.min_size, self.max_size)
  )
end

Spawn.family = setmetatable({}, { __index = Spawn })

function Spawn.family:new(spec)
  local s = {
    min_offspring = spec.min_offspring or 1,
    max_offspring = spec.max_offspring or 6,
    parent = wml.get_child(spec, "parent"),
    child = wml.get_child(spec, "child")
  }
  return setmetatable(s, { __index = self })
end

function Spawn.family:decorate(wml_tag, hex, side)
  local u = wml.merge(wml_tag, hex:coords(), "append")
  if not u.side then u.side = side end
  return u
end

function Spawn.family:placement(hex, side)
  local hexes = Hex.Set:new(filter(Spawn.valid_location, hex:circle(1)))
  return chain(
    iter({ self:decorate(self.parent, hex, side) }),
    repeatedly(
      function()
        if hexes.size > 0 then
          local h = hexes:pop_random()
          return self:decorate(self.child, hex, side)
        else
          return nil
        end
      end,
      mathx.random(self.min_offspring, self.max_offspring)
    )
  )
end

if wesnoth.wml_actions then -- only at runtime
  function wesnoth.wml_actions.spawn(spec)
    local spawn_proto = spec.type and Spawn[spec.type] or Spawn
    local spawn = spawn_proto:new(wml.literal(spec))
    local hex = Hex:from_wesnoth(wesnoth.map.get(spec.x, spec.y))
    spawn:spawn(hex, spec.side or wml.variables.current_side)
  end
end

return Spawn
