local Dialogue = reqwuire("scenario_toolbox/lua/events/dialogue")

Dyzma = {}

function Dyzma:new(spec)
  local dyzma = wesnoth.units.find({ id = "forest-boss"})[1]
  local fst = wesnoth.units.find({ id = wml.variables.summoner.id })[1]
  local snd = wesnoth.units.find({ side = spec.player_sides, wml.tag["not"]({ id = fst.id })})[1]
  local d = Dialogue:new()

  d:add(Dialogue.Line:new(fst, "Czy Las się przyzna, że w nim jest Dyzma?"))
  if snd then
    d:add(Dialogue.Line:new(snd, "Bo taki jest Las, ile Dyzmy wśród nas."))
  end
  d:add(Dialogue.Line:new(dyzma, "Najważniejsze dla mnie abym żył jak drzewo."))
  d:add(Dialogue.Line:new(fst, "Za długo już nie pożyjesz, Bratku."))
  d:add(Dialogue.Line:new(dyzma, "No tak to już dawno mnie nie obrażono. Czy ja wyglądam jak kwiat? Zginiecie za to!"))
end
