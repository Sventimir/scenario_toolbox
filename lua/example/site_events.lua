local Hex = require("scenario_toolbox/lua/map/hex")
local Spawn = require("scenario_toolbox/lua/units/spawn")

local Site = {}

function Site:new(s)
  return setmetatable(s or {}, { __index = self })
end

Site.burial = Site:new()

function Site.burial:spawn(spec)
  local filter = {
    time_of_day = "chaotic",
    wml.tag["not"]({ wml.tag.filter({}) }),
    wml.tag["and"](wml.get_child(spec, "location"))
  }
  local loc = Hex.Set:new(iter(wesnoth.map.find(filter)))
  if not loc:empty() then
    local spawns = as_table(
      filter_map(
        function(spawn)
          local side
          if type(spawn.side) == "number" then
            side = spawn.side
          else
            side = wesnoth.sides.find({ team_name = spec.side })
          end
          if side.side == wml.variables.side_number then
            local spec = wml.clone(spawn)
            spec.side = side.side
            return spec
          end
        end,
        iter(wml.child_array(spec, "spawn"))
      )
    )
    local spawn = Spawn:new(wml.literal(spawns[mathx.random(#spawns)]))
    spawn:spawn(loc:random(), side.side)
  end
end

return Site
