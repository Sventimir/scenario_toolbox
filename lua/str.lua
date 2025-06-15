local function split(input, sep)
  local separator = sep or "%s"
  return string.gmatch(input, "([^" .. separator .. "]+)")
end

return {
  split = split
}
