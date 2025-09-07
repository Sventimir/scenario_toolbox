Hex = require("scenario_toolbox/lua/map/hex")
Probability = require("scenario_toolbox/lua/lib/probability")

local River = {}

function River:new(hexes, ocean)
  local river = {
    river = Hex.Set:new(),
    ocean = ocean,
    counter = 1,
  }
  river.spring = hexes:random() 
  river.spring.height = -2
  river.bank = Hex.Set:new(river.spring:circle(1))
  return setmetatable(river, { __index = self })
end

function River:generate()
  local hex = self.bank:pop_random()
  for h in self.bank:iter() do
    h.height = 2
  end
  while not self.ocean:member(hex) do
    self.river:add(hex)
    hex.height = -1
    local neighbours = Hex.Set:new(
      filter(
        function(h) return not (self.river:member(h) or self.bank:member(h)) end,
        hex:circle(1)
      )
    )
    if neighbours:empty() then
      hex = self.river:random()
      self.bank = self.bank:diff(Hex.Set:new(hex:circle(1)))
    else
      hex = neighbours:pop_random()
    end
    self.bank = self.bank:union(neighbours)
  end
  local prob = Probability.Normal:new(1, 1)
  for hex in self.bank:iter() do
    hex.height = mathx.round(prob:sample(-1, 2))
  end
  self.river:add(self.spring)
end

return River
