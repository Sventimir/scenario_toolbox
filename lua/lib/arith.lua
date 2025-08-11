local mod = {}

function mod.add(x, y)
  return x + y
end

function mod.sub(x, y)
  return x - y
end

function mod.mul(x, y)
  return x * y
end

function mod.div(x, y)
  return x / y
end

-- Note: These start with 1, just like array indices.
function mod.nats()
  local n = 0
  return function()
    n = n + 1
    return n
  end
end

function mod.signum(x)
  if x < 0 then
    return -1
  elseif x > 0 then
    return 1
  else
    return 0
  end
end

function mod.trunc(x)
  if x > 0 then
    return x - mathx.floor(x)
  else
    return x + mathx.ceil(x)
  end
end

function mod.mean(it, state, ctrl)
  local total = 0
  local count = 0
  
  for val in it, state, ctrl do
    total = total + val
    count = count + 1
  end
  
  if count > 0 then
    return total / count
  else
    return nil
  end
end

function mod.gcd(a, b)
  while a > 0 and b > 0 do
    if a > b then
      a = a % b
    else
      b = b % a
    end
  end
  return mathx.max(a, b)
end

-- Ratios are mostly useful for random checks with some prescribed chance
-- of success. Therefore no need to implement other arith operations.
mod.Ratio = {}
mod.Ratio.__index = mod.Ratio

function mod.Ratio:new(num, denom)
  local norm = mod.gcd(num, denom)
  return setmetatable({ num = num // norm, denom = denom // norm }, self)
end

function mod.Ratio:__mul(other)
  return self:new(self.num * other.num, self.denom * other.denom)
end

function mod.Ratio:inverse()
  return self:new(self.denom, self.num)
end

function mod.Ratio:__div(other)
  return self * other:inverse()
end

-- Make a probability test with chance of success equal to the ratio.
-- Returns bool.
function mod.Ratio:prob_check()
  return mathx.random(self.denom) <= self.num
end

mod.Ratio.zero = mod.Ratio:new(0, 1)

function mod.Ratio.zero:prob_check()
  return false
end

return mod
