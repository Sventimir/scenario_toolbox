Dialogue = {}
Dialogue.__index = Dialogue

function Dialogue:new()
  return setmetatable({}, self)
end

function Dialogue:add(line)
  table.insert(self, line)
end

function Dialogue:play()
  for l in iter(self) do
    l:play()
  end
end

Dialogue.Line = {}
Dialogue.Line.__index = Dialogue.Line

function Dialogue.Line:new(speaker, message, title)
  return setmetatable({ speaker = speaker, message = message, title = title }, self)
end

function Dialogue.Line:play()
  gui.show_narration({
      portrait = self.speaker.portrait,
      title = self.title or self.speaker.name,
      message = self.message,
  })
end

Dialogue.Animation = {}
Dialogue.Animation.__index = Dialogue.Animation

function Dialogue.Animation:new(hex, halos, duration, sound)
  return setmetatable({ hex = hex, halos = halos, duration = duration, sound = sound }, self)
end

function Dialogue.Animation:play()
  if self.sound then
    wesnoth.audio.play(self.sound)
  end
  for halo in iter(self.halos) do
    wesnoth.interface.add_item_halo(self.hex.x, self.hex.y, halo)
    wesnoth.interface.delay(self.duration)
    wesnoth.interface.remove_item(self.hex.x, self.hex.y, halo)
  end
end

return Dialogue
