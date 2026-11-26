local T = ...
local source = debug.getinfo(1, "S").source
if source:sub(1, 1) == "@" then
  source = source:sub(2)
end
local ROOT = source:match("^(.*)[/\\]tests[/\\]") or "."

local wowTokens = {
  "C_Map", "CreateFrame", "UnitPosition", "GetBindLocation",
  "TaxiNodeName", "TAXIMAP_OPENED", "SlashCmdList", "UIParent",
  "SavedVariables", "GetZoneText", "UnitOnTaxi",
}

T.describe("architecture", function()
  T.it("core modules do not reference WoW APIs", function()
    local files = {
      "src/core/namespace.lua",
      "src/core/util.lua",
      "src/core/movement.lua",
      "src/core/data.lua",
      "src/core/graph.lua",
      "src/core/destinations.lua",
      "src/core/router.lua",
      "src/core/steps.lua",
    }
    for i = 1, #files do
      local fh = assert(io.open(ROOT .. "/" .. files[i], "r"))
      local body = fh:read("*a")
      fh:close()
      for t = 1, #wowTokens do
        local token = wowTokens[t]
        -- Allow the word in comments that mention the boundary, but not as code.
        -- A code use looks like `C_Map.` or `CreateFrame(` or a bare global assignment.
        if body:find(token .. "[%.%(]", 1) then
          error(files[i] .. " references WoW API " .. token)
        end
      end
    end
  end)
end)
