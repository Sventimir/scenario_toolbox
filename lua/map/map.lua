local Map = { Hex = require("scenario_toolbox/lua/map/hex") }
Map.__index = Map

function Map:new(width, height, terrain)
  local m = setmetatable({ width = width, height = height, default_terrain = terrain }, self)

  for y = 0, height do
    local row = {}
    for x = 0, width do
      row[x] = self.Hex:new(m, x, y, terrain)
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
    if state.x >= self.width then
      state.x = 0
      state.y = state.y + 1
    else
      state.x = state.x + 1
    end
    if state.y > self.height then
      return nil
    else
      return self[state.y][state.x]
    end
  end
  return it, { x = -1, y = 0 }
end

function Map:as_map_data()
  local map = ""

  for y = 0, self.height do
    local row = self[y]
    for x = 0, self.width do
      local node = row[x]
      if node.starting_player then
        map = map .. node.starting_player .. " "
      end
      if x < self.width then
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
        return wml.tag.labe({ x = hex.x, y = hex.y, text = hex.label })
      end
    end,
    self:iter()
  )
end

return Map
