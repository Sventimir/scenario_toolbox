local Scenario = {
  carryover_percentage = 50,
  carryover_add = true,
  victory_when_enemies_defeated = false,
  {"time", {
     id = "underground",
     name = "Podziemia",
     image = "misc/time-schedules/schedule-underground.png",
      lawful_bonus = -25,
      red = -60,
      green = -45,
      blue = -25
  }}
}

Scenario.__index = Scenario

function Scenario.new(id, name)
  return setmetatable({ id = id, name = name }, Scenario)
end

return Scenario
