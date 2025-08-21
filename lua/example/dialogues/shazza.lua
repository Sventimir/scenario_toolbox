local Dialogue = require("scenario_toolbox/lua/events/dialogue")

Shazza = {}

function Shazza:new(spec)
  local shazza = wesnoth.units.find({ id = "meadows-boss" })[1]
  local fst = wesnoth.units.find({ id = wml.variables.summoner.id })[1]
  local snd = wesnoth.units.find({ side = spec.player_sides, wml.tag["not"]({ id = fst.id }) })[1]
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
