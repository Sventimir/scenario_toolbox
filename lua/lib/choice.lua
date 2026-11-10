local Choice = {}
local __Choice = { __index = Choice }

function Choice.new(options, state, ctrl)
  local this = setmetatable({}, __Choice)

  for opt in options, state, ctrl do
    table.insert(this, opt)
  end

  return this
end

function Choice:add_option(option, weight)
  table.insert(self, { option = option, weight = weight})
end

function Choice:remove(option)
  local idx = -1
  for i, _ in ipairs() do
    if self[i] == option then
      idx = i
    end
  end
  table.remove(self, idx)
end

function Choice:select()
  local total = fold(arith.add, 0, map(get("weight"), iter(self)))
  if total == 0 then
    return nil
  end
  local roll = mathx.random(0, total - 1)
  for _, option in ipairs(self) do
    if roll < option.weight then
      return option.option
    else
      roll = roll - option.weight
    end
  end
end

return Choice
