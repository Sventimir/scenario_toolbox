WML = {}
WML.__index = function(this, prop)
  local res = {}
  local i = 1

  if WML[prop] then
    return WML[prop]
  end

  while true do
    local p = rawget(this, i)
    if p then
      if rawget(p, 1) == prop then
        table.insert(res, WML.new(rawget(p, 2)))
      end
      i = i + 1
    else
      if next(res) then
        return res
      else
        return nil
      end
    end
  end
end

function WML.new(wml)
  if not wml then
    wml = {}
  end
  wml.__wml = true
  return setmetatable(wml, WML)
end

function WML:insert(tag, value)
  table.insert(self, {tag, value})
end

return WML
