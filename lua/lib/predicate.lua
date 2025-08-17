local Predicate = {}
Predicate.__index = Predicate

function Predicate:new(f)
  return setmetatable({ f = f }, { __index = self })
end

function Predicate:func(f)
  return setmetatable({f = function(_, _, ...) return f(...) end }, { __index = self })
end

function Predicate:__call(...)
  return self:f(...)
end

function Predicate:__bnot()
  return self:new(function(...) return not self(...) end)
end

function Predicate:__band(q)
  return self:new(function(...) return self(...) and q(...) end)
end

function Predicate:__bor(q)
  return self:new(function(...) return self(...) or q(...) end)
end

function Predicate:gt(lim)
  return setmetatable({ lim = lim, f = function(self, _, x) return x > self.lim end }, Predicate)
end

function Predicate:lt(lim)
  return setmetatable({ lim = lim, f = function(self, _, x) return x < self.lim end }, Predicate)
end

function Predicate:eq(v)
  return setmetatable({ v = v, f = function(self, _, x) return x == self.v end }, Predicate)
end

function Predicate:neq(v)
  return setmetatable({ v = v, f = function(self, _, x) return x ~= self.v end }, Predicate)
end

function Predicate:gte(lim)
  return setmetatable({ lim = lim, f = function(self, _, x) return x >= self.lim end }, Predicate)
end

function Predicate:lte(lim)
  return setmetatable({ lim = lim, f = function(self, _, x) return x <= self.lim end }, Predicate)
end

function Predicate:in_range(low, high, low_open, high_open)
  local this = {
    low = low,
    high = high,
    low_open = low_open,
    high_open = high_open,
  }
  function this:f(x)
    return (self.low_open and self.low < x or self.low <= x)
      and (self.high_open and self.high > x or self.high >= x)
  end
  return setmetatable(this, Predicate)
end

function Predicate:has(key, value)
  local this = { key = key, value = value }
  if value then
    function this:f(x) return x and x[key] and x[key] == value end
  else
    function this:f(x) return x and x[key] end
  end
  return setmetatable(this, Predicate)
end

function Predicate:all(f)
  local this = { p = f }
  function this:f(it)
    return all(f, it)
  end
  return setmetatable(this, Predicate)
end

function Predicate:contra_map(f)
  local this = { m = f, p = self }
  function this:f(x)
    return self.p:f(self.m(x))
  end
  return setmetatable(this, Predicate)
end


return Predicate
