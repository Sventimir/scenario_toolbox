local Dialogue = require("scenario_toolbox/lua/events/dialogue")

local function Shazza(player_sides)
  local shazza = wesnoth.units.find({ id = "meadows-boss" })[1]
  fst = wesnoth.units.find({ id = wml.variables.summoner.id })[1]
  snd = wesnoth.units.find({ side = player_sides, wml.tag["not"]({ id = fst.id }) })[1]
  gui.show_lua_console()
  local d = Dialogue:new()

  d:add(Dialogue.Line:new(fst, "Shazza, Shazza, Shazza, Shazza!\nKtoś mi ciebie zabić kazał."))
  if snd then
    d:add(Dialogue.Line:new(snd, "O-o-o-o!"))
  end
  d:add(Dialogue.Line:new(fst, "Shazza, Shazza, Shazza, Shazza!\nDoprowadzam cię do ołtarza!"))
  d:add(Dialogue.Line:new(shazza, "Hauuuuu!"))

  return d
end

return Shazza
