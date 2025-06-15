require("scenario_toolbox/lua/hex")
require("scenario_toolbox/lua/hex")

Map = {}
Map.__index = Map

function Map.new(width, height, terrain)
  local m = setmetatable({ width = width, height = height, default_terrain = terrain }, Map)

  for y = 0, height + 1 do
    local row = {}
    for x = 0, width + 1 do
      row[x] = Hex.new(m, x, y, terrain)
    end
    m[y] = row
  end

  return m
end

function Map:get(x, y)
  return (self[y] or {})[x]
end

function Map:iter()
  local function it(state)
    if state.x > self.width then
      state.x = 0
      state.y = state.y + 1
    else
      state.x = state.x + 1
    end
    if state.y > self.height + 1 then
      return nil
    else
      return self[state.y][state.x]
    end
  end
  return it, { x = -1, y = 0 }
end

function Map:as_map_data()
  local map = ""

  for y = 0, self.height + 1 do
    local row = self[y]
    for x = 0, self.width + 1 do
      local node = row[x]
      if node.starting_player then
        map = map .. node.starting_player .. " "
      end
      if x < self.width + 1 then
          map = map .. node.terrain .. ", "
      else
        map = map .. node.terrain .. "\n"
      end
    end
  end

  return map
end

function Map:labels_wml()
  return map(
    function(hex)
      if hex.label then
        return { "label", { x = hex.x, y = hex.y, text = hex.label } }
      end
    end,
    self:iter()
  )
end

return Map
