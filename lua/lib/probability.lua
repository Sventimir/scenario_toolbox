-- The probability module allows for computing random variables
-- distributed along a given curve. A decent probabilitic model
-- should give:
-- * the probability density function
-- * the cumulative variant of the above (in fact its integral)
-- * the inverse of the cumulative distribution.
-- We want to deal with cumulative distributions, because unlike
-- usual distributions, they are bijections, which means we can
-- find their inverses. We're interested in inverses because
-- we typically want to sample a random value from the probability
-- space and then assign the base variable associated with that
-- probability. This way we can generate random variables with
-- an arbitrary distribution.
local Prob = {}

-- The generic constructor takes 3 functions listed above.
-- It's user's responsibility to provide the base function,
-- its integral and integral's inverse.
function Prob:new(p, cum, cum_inv)
  return setmetatable({ p = p, cum = cum, inv = cum_inv }, self)
end

function Prob:probability(x)
  return self.p(x)
end

function Prob:cumulative(x)
  return self.cum(x) - self.cum(self.min or 0)
end

function Prob:value(p)
  return self.inv(p)
end

function Prob:sample(min, max)
  local roll = mathx.random(min or self.min, max or self.max)
  return self.inv(roll)
end

Prob.Mock = setmetatable({}, Prob)

function Prob.Mock:sample(min, max)
  return mathx.random(min, max)
end

return Prob
