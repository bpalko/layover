#!/usr/bin/env lua
-- Print a few sample routes. Useful when you cannot log into the game.
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

local scenarios = {
  { "Alliance warrior, Elwynn → Ruins of Lordaeron (no Southshore)", T.allianceWarrior({ to = "ruins of lordaeron", hearthReady = false }) },
  { "Alliance warrior, Elwynn → Ruins of Lordaeron (Southshore known)", T.allianceWarrior({ to = "ruins of lordaeron", hearthReady = false, southshore = true }) },
  { "Alliance mage, Elwynn → Scarlet Monastery", T.allianceMage({ to = "sm", hearthReady = false, southshore = true }) },
  { "Alliance warrior, Elwynn → Darnassus", T.allianceWarrior({ to = "darnassus", hearthReady = false, knownFlights = { stormwind_fp = true, ironforge_fp = true, menethil_fp = true, auberdine_fp = true, ruttheran_fp = true } }) },
  { "Horde warrior, Orgrimmar → Scarlet Monastery", T.hordeWarrior({ to = "sm" }) },
}

for i = 1, #scenarios do
  print("============================================================")
  print(scenarios[i][1])
  print("============================================================")
  local r = Layover.Router.route(scenarios[i][2])
  print(Layover.Router.describe(r))
  print("")
end
