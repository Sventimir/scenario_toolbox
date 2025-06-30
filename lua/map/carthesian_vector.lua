require("scenario_toolbox/lua/lib/core")

local Vec = {}
Vec.__index = Vec

function Vec:new(x, y)
  return setmetatable({ x = x, y = y }, Vec)
end

Vec.north = Vec:new(0, -1)
Vec.east = Vec:new(1, 0)
Vec.south = Vec:new(0, 1)
Vec.west = Vec:new(-1, 0)

function Vec:translate(x, y)
  return x + self.x, y + self.y
end

function Vec:__add(other)
  return self:new(self.x + other.x, self.y + other.y)
end

function Vec:__sub(other)
  return self:new(self.x - other.x, self.y - other.y)
end

function Vec:__unm()
  return self:new(- self.x, - self.y)
end

function Vec:__tostring()
  return string.format("[%i, %i]", self.x, self.y)
end

function Vec:scale(f)
  return self:new(mathx.floor(self.x * f), mathx.floor(self.y * f))
end


return Vec
