local WML = require("scenario_toolbox/lua/wml/wml")

local Side = WML:new({
    controller = "human",
    gold = 0,
    income = 0,
    share_vision = "all"
})
Side.__index = Side

function Side:var(name, value)
  local vs = self:find("variables", 1)
  if not vs then
    vs = self:insert("variables", {})
  end
  vs[name] = value
end

return Side
