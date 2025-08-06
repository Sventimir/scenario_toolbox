goblin = { sp = 42 }

function goblin:new(x, y)
  local g = { x = x, y = y }
  return setmetatable(g, { __index = self })
end

function goblin:draw()
  print(string.format("goblin(%i) @ (%i, %i)", self.sp, self.x, self.y ))
end

hobgoblin = setmetatable({}, { __index = goblin })

function hobgoblin:hob()
  print("hob! hob!")
end

hg = hobgoblin:new(3, 4)
