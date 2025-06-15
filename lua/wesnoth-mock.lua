require("core")

local sides = {}
local units = { _units = {} }

local function create_unit(wml)
  units._units[wml.id] = wml
end

local function get_unit(id)
  return units._units[id]
end

units.get = get_unit
units.create = create_unit

local function create_side(side)
  sides[side] = { side = side, variables = {} }
end

-- WARNING: the filter is being ignored for the moment
local function iter_sides(filter) 
  local idx = 0
  return function()
    idx = idx + 1
    return sides[idx]
  end
end

sides.create = create_side
sides.iter = iter_sides

local function array_get(key, tbl)
  local res = tbl
  for k in str.split(key, ".") do
    res = res[k]
  end
  return res
end

local function role(args)
  local u = get_unit(args.id)
  u.role = args.role
end

local random_gen = map(function(n) return n - 1 end, int.nats())

wesnoth = {
  require = function(path)
    local filename, _ = string.gsub(path, "~add%-ons/above%-and%-below/lua/", "")
    local modname, _ = string.gsub(filename, "%.lua", "")
    return require(modname)
  end,
  sides = sides,
  units = units,
  wml_actions = { role = role }
}

wml = {
  array_access = {
    get = array_get
  }
}

mathx = math

mathx.choose_random = function(tbl)
  return tbl[mathx._random_gen() % #tbl]
end
