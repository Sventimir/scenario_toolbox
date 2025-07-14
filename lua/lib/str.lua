local function split(input, sep)
  local separator = sep or "%s"
  return string.gmatch(input, "([^" .. separator .. "]+)")
end

local function join(strs, separator)
  local ret = ""
  local sep = separator or ""
  for s in strs do
    ret = ret .. sep .. s
  end
  return ret
end

return {
  split = split,
  join = join
}
