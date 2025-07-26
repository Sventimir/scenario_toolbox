package.path = package.path .. ";/home/sven/code/wesnoth/?.lua"
require("scenario_toolbox/lua/lib/core")

z = {
  x = 4,
  y = 5,
  sub = {
    x = 3,
    y = 6,
    sub = { 2, 3, 4 }
  }
}
