if not pcall(function() return require end) then
  require = function(mod)
    return wesnoth.require(string.format("~add-ons/%s.lua", mod))
  end
end
if not mathx then
  mathx = math
  function mathx.random_choice(input)
    return input[mathx.random(#input)]
  end
end

function as_table(iter, state, ctrl)
  local t = {}
  for item in iter, state, ctrl do
    table.insert(t, item)
  end
  return t
end

function iter(tbl)
  if not tbl then
    return function() return nil end
  else
    local i = 0
    return function()
      i = i + 1
      return tbl[i]
    end
  end
end

function take(n, iter, state, ctrl)
  local s = { intern = state, ctrl = ctrl, n = n }
  return function()
    if s.n > 0 then
      s.ctrl = iter(s.intern, s.ctrl)
      s.n = s.n - 1
      return s.ctrl
    end
  end
end

function take_while(f, iter)
  return function()
    local item = iter()
    if f(item) then
      return item
    else
      return nil
    end
  end
end


function drop(n, iter, state, ctrl)
  local s = { inter = state, ctrl = ctrl }
  for _ = 1, n do
    s.ctrl = iter(s.intern, s.ctrl)
  end
  return function()
    return iter(s.intern, s.ctrl)
  end
end


function map(f, iter, state, ctrl)
  local s = { ctrl = ctrl, intern = state }
  local function it()
    s.ctrl = iter(s.intern, s.ctrl)
    if s.ctrl == nil then
      return nil
    else
      return f(s.ctrl) or it()
    end
  end
  return it
end

function fold(f, acc, iter, state, ctrl)
  local res = acc
  for item in iter, state, ctrl do
    res = f(res, item)
  end
  return res
end

function filter(predicate, iter, iter_state, ctrl)
  local state = { ctrl = ctrl, intern = iter_state }
  return function(_, ctrl)
    state.ctrl = iter(state.intern, state.ctrl)
    while state.ctrl ~= nil and not predicate(state.ctrl) do
      state.ctrl = iter(state.intern, state.ctrl)
    end
    return state.ctrl
  end
end

function filter_map(f, iter, state, ctrl)
  local s = { ctrl = ctrl, intern = state }
  return function()
    s.ctrl = iter(s.intern, s.ctrl)
    while s.ctrl ~= nil do
      local res = f(s.ctrl)
      if res ~= nil then
        return res
      else
        s.ctrl = iter(s.intern, s.ctrl)
      end
    end
  end
end

function pack_iter(iter, state, ctrl)
  local s = { ctrl = ctrl, intern = state }
  return function()
    s.ctrl = iter(s.intern, s.ctrl)
    return s.ctrl
  end
end

function zip(iter1, iter2)
  return function()
    local x = iter1()
    local y = iter2()
    if x and y then
      return x, y
    end
  end
end

function cycle(tbl)
  local i = 0
  return function()
    if i < #tbl then
      i = i + 1
    else
      i = 1
    end
    return tbl[i]
  end
end

function chain(...)
  local iters = {...}
  local i = 1
  return function()
    local item = iters[i]()
    while item == nil and i < #iters do
      i = i + 1
      item = iters[i]()
    end
    return item
  end
end

function repeatedly(f, times)
  local i = 0
  return function()
    i = i + 1
    if not times or i < times then
      return f(i)
    end
  end
end

-- Monadic join for iterators
function join(it)
  local current = it()
  return function()
    local ret = current and current()
    while current and not ret do
      current = it()
      ret = current and current()
    end
    return ret
  end
end

-- Returns the first item (if any) in the iterator that satisfies the predicate.
function any(f, iter, state, ctrl)
  for item in iter, state, ctrl do
    if f == nil or f(item) then
      return item
    end
  end
end

function all(f, iter, state, ctrl)
  for item in iter, state, ctrl do
    if not f(item) then
      return false
    end
  end
  return true
end

function count(it, state, ctrl)
  local total = 0
  for _ in it, state, ctrl do
    total = total + 1
  end
  return total
end

function get(key)
  return function(tbl)
    return tbl[key]
  end
end

function display_table(t)
  print("table:")
  for k, v in pairs(t) do
    print(string.format("%s = %s", k, v))
  end
end

function keys(t)
  local keys = {}
  for k, _ in pairs(t) do
    table.insert(keys, k)
  end
  return keys
end

arith = require("scenario_toolbox/lua/lib/arith")
str = require("scenario_toolbox/lua/lib/str")
