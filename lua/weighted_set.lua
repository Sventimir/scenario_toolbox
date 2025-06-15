Weighted = {}
Weighted.__index = Weighted

function Weighted.new(item, weight)
  return setmetatable({ item = item, weight = weight }, Weighted)
end

WeightedSet = {}
WeightedSet.__index = WeightedSet

function WeightedSet.new()
  return setmetatable({ items = {}, total = 0 }, WeightedSet)
end

function WeightedSet:insert(item, weight)
  self.total = self.total + weigth
  table.insert(self.items, Weighted.new(item, weight))
end

function WeightedSet:random()
  if self.total > 0 then
    local r = mathx.random(1, total_weight)
    for item in iter(self.items) do
      r = r - item.weight
      if r <= 0 then
        return item.item
      end
    end
  end
end

return WeightedSet
