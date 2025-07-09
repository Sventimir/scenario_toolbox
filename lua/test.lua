package.path = package.path .. ";/home/sven/code/wesnoth/?.lua"
require("scenario_toolbox/lua/lib/core")
WML = require("scenario_toolbox/lua/wml/wml")
Gen = require("scenario_toolbox/lua/example/generator")


cfg = WML:new({
    width = 30,
    height = 30,
    player_count = 2,
    WML:tag("scenario", {
              id = "example",
              name = "Example",
              WML:tag("time", {
                        id = "first_watch",
                        name = "First watch",
              }),
              WML:tag("time", {
                        id = "second_watch",
                        name = "Second watch",
              }),
    })
})

m = Gen:make(cfg)

print(m:__tostring())
