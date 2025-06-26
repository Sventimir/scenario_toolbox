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

return mod
