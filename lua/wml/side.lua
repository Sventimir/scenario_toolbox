local WML = require("scenario_toolbox/lua/wml/wml")

local Side = WML:new({
    controller = "human",
    gold = 0,
    income = 0,
    share_vision = "all"
})
Side.__index = Side

return Side
