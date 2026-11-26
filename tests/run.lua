#!/usr/bin/env lua
-- Offline test runner for Layover core modules (no WoW client required).
-- Usage: lua tests/run.lua

local source = debug.getinfo(1, "S").source
if source:sub(1, 1) == "@" then
  source = source:sub(2)
end
local ROOT = source:match("^(.*)[/\\]tests[/\\]")
if not ROOT or ROOT == "" then
  ROOT = "."
end

dofile(ROOT .. "/tests/load.lua")
LoadLayoverCore()

local T = dofile(ROOT .. "/tests/lib.lua")

local files = {
  "test_movement.lua",
  "test_destinations.lua",
  "test_router.lua",
  "test_faction.lua",
  "test_flights.lua",
  "test_steps.lua",
  "test_architecture.lua",
}

for i = 1, #files do
  local path = ROOT .. "/tests/" .. files[i]
  local chunk, err = loadfile(path)
  if not chunk then
    error("cannot load " .. path .. ": " .. tostring(err))
  end
  chunk(T)
end

print(string.format("\n%d passed, %d failed", T.passed, T.failed))
if T.failed > 0 then
  print("\nFailures:")
  for i = 1, #T.errors do
    print(" - " .. T.errors[i])
  end
  os.exit(1)
end
