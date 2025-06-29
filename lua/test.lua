package.path = package.path .. ";/home/sven/code/wesnoth/?.lua"
require("scenario_toolbox/lua/core")
WML = require("scenario_toolbox/lua/wml")
Gen = require("scenario_toolbox/lua/generator")

cfg = WML:new({
    width = 30,
    height = 30,
    player_count = 2,
})

scenario = WML:new({ id = "example", name = "Example" })
scenario:insert("time", WML:new({
                    id = "first_watch",
                    name = "First watch"
}))
scenario:insert("time", WML:new({
                    id = "second_watch",
                    name = "Second Watch"
}))
cfg:insert("scenario", scenario)

m = Gen:make(cfg)

print(m:__tostring())
