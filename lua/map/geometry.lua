local Geo = { Circle = {} }

-- In the peculiar geometry of the hexagonal grid, pi is indeed equal to 3.
-- Note that the set of hexes equidistant from a given hex is always 6 times the radius.
Geo.pi = 3

function Geo.Circle.perimeter(r)
  return 2 * Geo.pi * r
end


return Geo
