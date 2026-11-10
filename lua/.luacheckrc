package.path = package.path .. ";/home/sven/code/wesnoth/?.lua"
require("scenario_toolbox/lua/lib/core")

read_globals = { "gui", "mathx", "wesnoth", "wml" }


-- Load script with constants and add to populate dest_globals.
local function append_globals(dest_globals, script)
    -- Create a fallback env so lua stdlib is available, but we
    -- have a clean list of globals.
    local env = setmetatable({}, {__index = _G})
    local fn = loadfile(script, "t", env)
    fn()
    for key,val in pairs(env) do
        table.insert(dest_globals, key)
    end
end

-- Pass a global table created above to populate with globals:
-- read_globals, files["*.lua"].read_globals, etc.
xpcall(append_globals, print, read_globals, "/home/sven/code/wesnoth/scenario_toolbox/lua/lib/core.lua")

files["core.lua"] = {
  ignore = { "111", "112", "121", "122" }
}