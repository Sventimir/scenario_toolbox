local Hex = require("scenario_toolbox/lua/map/hex")
local Prob = require("scenario_toolbox/lua/lib/probability")

local Burial = {
  name = "burial",
  image = "items/burial.png",
  visible_in_fog = true
}
local __Burial = { __index = Burial }

function Burial.new(biome, spec)
  local this = {
    biome = biome,
    variables = {
      title = "Miejsce pochówku",
      description = "Miejsce pochówku dawnego bohatera. Pewnie jest nawiedzone..."
    },
    count = spec.count,
    spawn = wml.child_array(spec, "spawn"),
    distance = {}
  }
  for loc in iter({ "origin", "altar" }) do
    local dist = wml.get_child(spec, "distance_from_" .. loc)
    this.distance[loc] = {
      minimum = dist.minimum,
      maximum = dist.maximum,
      prob = Prob.Normal:new(dist.mean, dist.standard_deviation)
    }
  end
  return setmetatable(this, __Burial)
end

Burial.Hex = setmetatable({ site = "burial" }, Hex.__Gen)
Burial.__Hex = { __index = Burial.Hex }

function Burial.Hex.new(x, y)
  return setmetatable(Hex.Gen.new(x, y), Burial.__Hex)
end

function Burial.Hex:generate(map)
  local neighbours = map:circle(self, 1)
  self.height = self:gen_height(neighbours, map)
  self.biome = self.prototype.biome
  self.overlay = self:gen_overlay(neighbours, map)
end

function Burial.Hex:gen_height() -- luacheck: ignore 212 (unused 'self' required by interface)
  local height = Prob.Normal:new(1, 1)
  return height:sample(0, 2)
end

function Burial.Hex:propagate() -- luacheck:ignore 212 (unused 'self' required by the interface)
  return { option = Hex.Gen, weight = 1 }
end

function Burial.Hex:item()
  local spec = self:coords()
  spec.name = self.prototype.name
  spec.image = self.prototype.image
  spec.visible_in_fog = true
  table.insert(spec, wml.tag.variables(self.prototype.variables))
  return spec
end

function Burial.Hex:wml()
  local neighbourhood = self:coords()
  neighbourhood.radius = 5

  local current_spawn = {
    wml.tag.filter({
        side = "$side_number", -- current side
        role = "burial"
    }),
    wml.tag["and"](wml.clone(neighbourhood))
  }
  local spawn_args = {
    wml.tag.location(neighbourhood)
  }
  for spawn in iter(self.spawn) do
    table.insert(spawn_args, wml.tag.spawn(spawn))
  end
  local lua = {
    code = [[ local Site = require("scenario_toolbox/lua/example/site_events")
              Site.burial:new():spawn(...)
           ]],
    wml.tag.args(spawn_args)
  }
  local spawn_event = {
    name = string.format("side turn"),
    id = string.format("burial-spawn-%i-%i", self.x, self.y),
    first_time_only = false,
    wml.tag.filter_condititon({
        wml.tag.have_location({
            wml.tag.filter({
                wml.tag.filter_side({
                    team_name = "Bohaterowie"
                })
            }),
            wml.tag["and"](neighbourhood)
        }),
        wml.tag["not"]({ wml.tag.have_location(current_spawn) })
    }),
    wml.tag.lua(lua)
  }

  local micro_ai_setup = {
    name = "start",
    first_time_only = true,
    wml.tag.micro_ai({
        ai_type = "zone_guardian",
        side = "1,2,3,4,5,6,7,8", -- not a problem, since there's a role filter
        action = "add",
        wml.tag.filter({ role = "burial" }),
        wml.tag.filter_location(neighbourhood)
    })
  }

  return {
    wml.tag.item(self:item()),
    wml.tag.event(spawn_event),
    wml.tag.event(micro_ai_setup)
  }
end

function Burial:sample_distance(spec) -- luacheck: ignore 212 (unused 'self' required by interface)
  return spec.prob:sample_int(spec.minimum, spec.maximum)
end

function Burial:place(map, frontier)
  local origin = map.index.origin[1]
  local altar = any(
    function(alt) return alt.biome.name == "meadows" end,
    iter(map.index.altars or {})
  )
  if not altar then return end
  local alt_origin_dist = origin:distance(altar)
  local dist_origin = self:sample_distance(self.distance.origin)
  local min_altar_dist = mathx.abs(alt_origin_dist - dist_origin)
  local max_altar_dist = alt_origin_dist + dist_origin
  self.distance.altar.minimum = mathx.max(self.distance.altar.minimum, min_altar_dist)
  self.distance.altar.maximum = mathx.min(self.distance.altar.maximum, max_altar_dist)
  self.distance.altar.prob.mean = arith.mean(
    iter({ self.distance.altar.minimum, self.distance.altar.maximum })
  )
  local dist_altar = self:sample_distance(self.distance.altar)
  local orig_circ = Hex.Set:new(origin:circle(dist_origin))
  local altar_circ = Hex.Set:new(altar:circle(dist_altar))
  local hexes = orig_circ:intersect(altar_circ)
  for h in hexes:iter() do
    local hex = self.Hex.new(h)
    hex.prototype = self
    hex:generate(map)
    map:add(hex)
    for n in hex:circle(1) do
      frontier:add(n)
    end
  end
end

return Burial
