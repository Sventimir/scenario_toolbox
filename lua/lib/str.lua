local function split(input, sep)
  local separator = sep or "%s"
  return string.gmatch(input, "([^" .. separator .. "]+)")
end

local function join(strs, separator)
  local ret = strs()
  local sep = separator or ""
  for s in strs do
    ret = ret .. sep .. s
  end
  return ret or ""
end

return {
  split = split,
  join = join
}
