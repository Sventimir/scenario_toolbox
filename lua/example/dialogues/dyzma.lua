local Dialogue = require("scenario_toolbox/lua/events/dialogue")

Dyzma = {}

function Dyzma:new(spec)
  local dyzma = wesnoth.units.find({ id = "forest-boss"})[1]
  local fst = wesnoth.units.find({ id = wml.variables.summoner.id })[1]
  local snd = wesnoth.units.find({ side = spec.player_sides, wml.tag["not"]({ id = fst.id })})[1]
  local side_numbers = string.split(spec.player_sides, ",")
  local panzer = wesnoth.units.create({
      type = "Heavy Infantryman",
      side = side_numbers[mathx.random(#player_sides)],
  })
  local d = Dialogue:new()

  d:add(Dialogue.Line:new(fst, "Czy Las się przyzna, że w nim jest Dyzma?"))
  if snd then
    d:add(Dialogue.Line:new(snd, "Bo taki jest Las, ile Dyzmy wśród nas."))
  end
  d:add(Dialogue.Line:new(dyzma, "Ludzie to za dużo teraz żrą!"))
  d:add(Dialogue.Line:new(dyzma, "Ludzie coraz cięższe teraz są!"))
  d:add(Dialogue.Line:new(panzer, "Uważaj sobie! Gdybym nie był związany, to tak bym ci przywalił moją pałą...")) 
  d:add(Dialogue.Line:new(dyzma, "... ale najważniejsze dla mnie abym żył jak drzewo."))
  d:add(Dialogue.Line:new(panzer, "To drzewo jest zdrowo jebnięte. I to nie moja sprawka, niestety."))
  d:add(Dialogue.Line:new(panzer, "Zetnijcie je co rychlej i uwolnijcie mnie, a przyłączę się do was."))
  d:add(Dialogue.Line:new(fst, "Zobaczymy, co da się zrobić."))
  wml.variables.panzer_captive = panzer

  return d
end

return Dyzma
