Prob = { Normal = { mean = 0, stddev = 1 } }
Prob.__index = Prob

function Prob.Normal:new(mean, stddev)
  return setmetatable(
    { mean = mean or 0, stddev = stddev or 1 },
    { __index = self }
  )
end

function Prob.Normal:from_wml(spec)
  return self:new(spec.mean, spec.standard_deviation)
end

function Prob.Normal:probability(x)
  local exp = -0.5 * ((x - self.mean) / self.stddev) ^ 2
  return 1 / (mathx.sqrt(2 * mathx.pi) * self.stddev) * mathx.exp(exp)
end

-- Sample any normally distributed real number, expecting 0
-- with standard deviation of 1. Use Box-Muller transform.
-- This method generates 2 random values in one go, so we can
-- store one of them for later use.
function Prob.Normal:box_muller()
  local u = mathx.random()
  local v = 2 * mathx.pi * mathx.random()
  local r = mathx.sqrt(-2 * mathx.log(u))
  self.__store = r * mathx.sin(v)
  return r * mathx.cos(v)
end

function Prob.Normal:sample_real()
  local ret
  if self.__store then
    ret = self.__store
    self.__store = nil
  else
    ret = self:box_muller()
  end
  return self.stddev * ret + self.mean
end

function Prob.Normal:sample(min, max)
  return mathx.min(max, mathx.max(min, self:sample_real()))
end

function Prob.Normal:sample_int(min, max)
  return mathx.round(self:sample(min, max))
end

return Prob
