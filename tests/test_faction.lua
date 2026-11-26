local T = ...

local function assertNoOpposing(result, playerFaction)
  T.truthy(result.ok, T.dumpRoute(result))
  local opposed = (playerFaction == "Alliance") and "Horde" or "Alliance"
  for i = 1, #(result.path or {}) do
    local e = result.path[i]
    if e.mode == "flight" or e.mode == "zeppelin" or e.mode == "tram" then
      T.neq(e.faction, opposed, e.mode .. " " .. tostring(e.from) .. "->" .. tostring(e.to) .. " used opposing faction\n" .. T.dumpRoute(result))
    end
  end
  local factions = Layover.Router.pathFactions(result)
  T.falsy(factions[opposed], T.dumpRoute(result))
end

T.describe("faction isolation", function()
  T.it("Alliance never rides Horde zeppelins or Horde flight paths", function()
    local dests = { "sm", "undercity", "orgrimmar", "booty bay", "gadgetzan", "darnassus" }
    for i = 1, #dests do
      local r = Layover.Router.route(T.allianceWarrior({
        to = dests[i],
        hearthReady = false,
        southshore = true,
      }))
      assertNoOpposing(r, "Alliance")
      T.falsy(T.hasMode(r, "zeppelin"), dests[i] .. "\n" .. T.dumpRoute(r))
    end
  end)

  T.it("Horde never uses Deeprun Tram or Alliance-only flights", function()
    local dests = { "sm", "stormwind", "ironforge", "booty bay", "darnassus" }
    for i = 1, #dests do
      local r = Layover.Router.route(T.hordeWarrior({
        to = dests[i],
        hearthReady = false,
      }))
      assertNoOpposing(r, "Horde")
      T.falsy(T.hasMode(r, "tram"), dests[i] .. "\n" .. T.dumpRoute(r))
    end
  end)

  T.it("Alliance cannot fly from Tarren Mill", function()
    local r = Layover.Router.route(T.allianceWarrior({
      to = "sm",
      hearthReady = false,
      knownFlights = {
        stormwind_fp = true,
        ironforge_fp = true,
        menethil_fp = true,
        tarren_mill_fp = true,
        southshore_fp = true,
      },
    }))
    T.truthy(r.ok, T.dumpRoute(r))
    -- Even if the node is marked known, the edge is Horde-only.
    T.falsy(T.hasNode(r, "tarren_mill_fp") and T.hasMode(r, "flight") and (function()
      for i = 1, #r.path do
        if r.path[i].mode == "flight" and (r.path[i].from == "tarren_mill_fp" or r.path[i].to == "tarren_mill_fp") then
          return true
        end
      end
      return false
    end)(), T.dumpRoute(r))
  end)
end)
