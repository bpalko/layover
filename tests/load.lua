local ROOT = ...
if type(ROOT) ~= "string" or ROOT == "" then
  local source = debug.getinfo(1, "S").source
  if source:sub(1, 1) == "@" then
    source = source:sub(2)
  end
  ROOT = source:match("^(.*)[/\\]tests[/\\]")
end
if not ROOT or ROOT == "" then
  ROOT = "."
end

package.path = ROOT .. "/?.lua;" .. ROOT .. "/src/?.lua;" .. (package.path or "")

local function loadfile_into(path)
  local chunk, err = loadfile(path)
  if not chunk then
    error("failed to load " .. path .. ": " .. tostring(err))
  end
  chunk()
end

function LoadLayoverCore()
  _G.Layover = {}
  loadfile_into(ROOT .. "/src/core/namespace.lua")
  loadfile_into(ROOT .. "/src/core/util.lua")
  loadfile_into(ROOT .. "/src/core/movement.lua")
  loadfile_into(ROOT .. "/src/core/data.lua")
  loadfile_into(ROOT .. "/src/core/graph.lua")
  loadfile_into(ROOT .. "/src/core/destinations.lua")
  loadfile_into(ROOT .. "/src/core/router.lua")
  loadfile_into(ROOT .. "/src/core/steps.lua")
  Layover.Graph.build()
  return Layover
end

return {
  root = ROOT,
  load = LoadLayoverCore,
}
