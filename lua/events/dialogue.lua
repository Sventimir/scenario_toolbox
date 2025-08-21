Dialogue = {}

function Dialogue:new()
  return setmetatable({ interrupted = false }, { __index = self })
end

function Dialogue:add(line)
  table.insert(self, line)
end

function Dialogue:play()
  for l in iter(self) do
    if l:play(self.interrupted) == -2 then -- user pressed Esc.
      self.interrupted = true
    end
  end
end

Dialogue.Entry = {}

function Dialogue.Entry:play(interrupted)
  if not interrupted then
    return self:display()
  end
end

Dialogue.Line = setmetatable({}, { __index = Dialogue.Entry })

function Dialogue.Line:new(speaker, message, title)
  return setmetatable(
    { speaker = speaker, message = message, title = title }
    , { __index = self }
  )
end

function Dialogue.Line:display()
  return gui.show_narration({
      portrait = self.speaker.portrait,
      title = self.title or self.speaker.name,
      message = self.message,
  })
end

Dialogue.Animation = setmetatable({}, { __index = Dialogue.Entry })

function Dialogue.Animation:new(hex, halos, duration, sound)
  return setmetatable(
    { hex = hex, halos = halos, duration = duration, sound = sound }
    , { __index = self }
  )
end

function Dialogue.Animation:display()
  if self.sound then
    wesnoth.audio.play(self.sound)
  end
  for halo in iter(self.halos) do
    wesnoth.interface.add_item_halo(self.hex.x, self.hex.y, halo)
    wesnoth.interface.delay(self.duration)
    wesnoth.interface.remove_item(self.hex.x, self.hex.y, halo)
  end
end

if wesnoth.wml_actions then
  function wesnoth.wml_actions.dialogue(spec)
    local D = require(spec.filename)
    local d = D:new(spec)
    d:play(spec)
  end
end

return Dialogue
