local WML = { __wml = true }

function WML:new(wml)
  local this = wml or {}
  if not this.__wml_tag then
    setmetatable(this, self)
  end
  self.__index = self
  return this
end

function WML:tag(name, content)
  return WML.Tag:new(name, content)
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

function WML:merge(wml)
  for k, v in pairs(wml) do
    if type(k) == "number" then
      table.insert(self, v)
    else
      self[k] = v
    end
  end
end

function WML:insert(tag, value)
  local contents
  if tag.__wml_tag then
    contents = tag
  else
    contents = WML:tag(tag, value)
  end
  table.insert(self, contents)
  return contents[2]
end

function WML:pretty_print(indent)
  local out = ""
  for name, value in pairs(self) do
    if string.sub(name, 1, 2) == "__" then
    elseif type(value) == "table" and value.pretty_print then
      out = string.format("%s%s", out, value:pretty_print(indent))
    elseif tonumber(name) then
      out = string.format("%s%s", out, WML.Tag:new(value[1], value[2]):pretty_print(indent))
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

function WML:clone()
  local result = WML:new()
  for k, v in pairs(self) do
    result[k] = v
  end
  return result
end

function WML:__band(other)
  local result = self:clone()
  if other.__wml_tag then
    result:insert(other)
  else
    result:merge(other)
  end
  return result
end

function WML:__bor(other)
  local result = self:clone()
  result:insert(WML:tag("or", other))
  return result
end

function WML:__bnot()
  return WML:tag("not", self)
end

WML.Tag = { __wml = true, __wml_tag = true }
WML.Tag.__index = WML.Tag

function WML.Tag:new(name, content)
  return setmetatable(WML:new({ name, WML:new(content) }), WML.Tag)
end

function WML.Tag:find(tag, index)
  return self[2]:find(tag, index)
end

function WML.Tag:set(k, v)
  self[2][k] = v
end

function WML.Tag:get(k)
  return self[2][k]
end

function WML.Tag:merge(wml)
  setmetatable(self, WML)
  local name = table.remove(self, 1)
  local contents = table.remove(self, 2)
  self[1] = WML.Tag:new(name, content)
  self:merge(wml)
end

function WML.Tag:insert(tag, content)
  return self[2]:insert(tag, content)
end

function WML.Tag:pretty_print(indent)
  return string.format("%s[%s]\n%s%s[/%s]\n",
                       indent,
                        self[1],
                       self[2]:pretty_print("  " .. indent),
                       indent,
                       self[1]
  )
end

function WML.Tag:__tostring()
  return self:pretty_print("")
end

function WML.Tag:__bnot()
  return WML.Tag:new("not", WML:new({ self }))
end

function WML.Tag:__band(other)
  return WML:new({ self }) & other
end

function WML.Tag:__bor(other)
  return WML:new({ self }) | other
end

return WML
