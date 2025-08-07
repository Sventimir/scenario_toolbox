local Dialogue = require("scenario_toolbox/lua/events/dialogue")

local baziol = wesnoth.units.create({
    type = "White Mage",
    profile = "misc/tod-bright.png",
    name = "Baziol",
})

local function Opening(origin)
  local d = Dialogue:new()

  local heroes = wesnoth.units.find({ side = "1,2", canrecruit = true })
  local fst = heroes[1]
  local snd = heroes[2] or heroes[1]
  local animation = as_table(
    map(
      function(i) return string.format("halo/holy/light-beam-%i.png", i) end,
      take(7, arith.nats())
    )
  )

  d:add(Dialogue.Line:new(fst, "Moja głowa. Co tu się wczoraj działo?"))
  d:add(Dialogue.Line:new(snd, "Nie kojarzę tego miejsca. Czyżbyśmy zachlali na śmierć?"))
  d:add(Dialogue.Animation:new(origin, animation, 100, "magic-holy-1.ogg"))
  d:add(Dialogue.Line:new(baziol, "To ja was tu ściągnąłem, abyście wykonali dla mnie niezwykle ważną misję."))
  d:add(Dialogue.Line:new(fst, "Na Wielkiego Baziola, toż to Baziol!"))
  d:add(Dialogue.Line:new(baziol, "Nie, kurwa, Święty Mikołaj."))
  d:add(Dialogue.Line:new(snd, "Czyżby chodziło o wpierdol?"))
  d:add(Dialogue.Line:new(baziol, "Nie inaczej. Po tych łąkach grasuje prastara wilczyca Shazza. Przynieścia mi tu jej łeb, a nagrodzę was wielką mocą!"))
  d:add(Dialogue.Line:new(baziol, "Odnajdźcie jej ołtarz i zadbajcie o odpowiednia ofiarę, która przyciągnie ją do tego świata"))
  d:add(Dialogue.Line:new(fst, "Stanie się jak powiedziałeś! W drogę!"))

  return d
end

return Opening
