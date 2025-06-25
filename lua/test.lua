package.path = package.path .. ";/home/sven/code/wesnoth/?.lua"
require("scenario_toolbox/lua/core")
WML = require("scenario_toolbox/lua/wml")
Gen = require("scenario_toolbox/lua/generator")

cfg = WML.new({
    width = 30,
    height = 30
})

cfg:insert("scenario", { id = "example", name = "Example" })

m = Gen:make(cfg)
display_table(m)
