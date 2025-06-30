local WML = {}

function WML:new(wml)
  local this = wml or {}
  this.__wml = true
  setmetatable(this, self)
  self.__index = self
  return this
end

function WML:find(tag, index)
  local res = {}
  local i = 1

  while true do
    local p = rawget(self, i)
    if p then
      if rawget(p, 1) == tag then
        table.insert(res, WML:new(rawget(p, 2)))
        if #res == index then
          return res[index]
        end
      end
      i = i + 1
    else
      if not index then
        return res
      else
        return nil
      end
    end
  end
end

function WML:insert(tag, value)
  table.insert(self, {tag, value})
end

function WML:pretty_print(indent)
  local out = ""
  for name, value in pairs(self) do
    if string.sub(name, 1, 2) == "__" then
    elseif tonumber(name) then
      if value[2].__wml then
        content = value[2]:pretty_print(indent .. "  ")
      else
        content = self:new(value[2]):pretty_print(indent .. "  ")
      end
      out = string.format("%s%s[%s]\n%s%s[/%s]\n", out, indent, value[1], content, indent, value[1])
    else
      if type(value) == string then
        content = string.format("\"%s\"", value)
      else
        content = tostring(value)
      end
      out = string.format("%s%s%s = %s\n", out, indent, name, content)
    end
  end
  return out
end

function WML:__tostring()
  return self:pretty_print("")
end

return WML
