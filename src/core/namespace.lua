-- Shared addon namespace. Works as a TOC file (`...` is addon name + table)
-- and as a dofile/require from the offline test runner.
local name, addonTable = ...
if name == "Layover" and type(addonTable) == "table" then
  _G.Layover = addonTable
else
  _G.Layover = _G.Layover or {}
end

local addon = _G.Layover
addon.version = "1.0.0"
addon.addonName = addon.addonName or "Layover"
