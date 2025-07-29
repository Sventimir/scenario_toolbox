local Dialogue = require("scenario_toolbox/lua/events/dialogue")

local function Shazza(shazza, fst, snd)
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
