local T = ...

T.describe("known vs undiscovered flight paths", function()
  T.it("cannot fly from an undiscovered node", function()
    local r = Layover.Router.route(T.allianceWarrior({
      to = "southshore",
      hearthReady = false,
      knownFlights = { stormwind_fp = true, ironforge_fp = true }, -- no Menethil
    }))
    T.truthy(r.ok, T.dumpRoute(r))
    -- Without Menethil known, the Southshore flight (Menethil→Southshore) is unavailable.
    local flewToSS = false
    for i = 1, #(r.path or {}) do
      local e = r.path[i]
      if e.mode == "flight" and e.to == "southshore_fp" then
        flewToSS = true
      end
    end
    T.falsy(flewToSS, T.dumpRoute(r))
  end)

  T.it("preferDiscover actually uses the unknown Southshore hop", function()
    local r = Layover.Router.route(T.allianceWarrior({
      to = "ruins of lordaeron",
      hearthReady = false,
      southshore = false,
      preferDiscover = true,
    }))
    T.truthy(r.ok, T.dumpRoute(r))
    T.truthy(T.hasNode(r, "southshore_fp"), T.dumpRoute(r))
    local sawDiscover = false
    for i = 1, #r.steps do
      if r.steps[i].discover then
        sawDiscover = true
      end
    end
    T.truthy(sawDiscover, T.dumpRoute(r))
  end)

  T.it("with Southshore already known it is used, not suggested as a discovery", function()
    local r = Layover.Router.route(T.allianceWarrior({
      to = "ruins of lordaeron",
      hearthReady = false,
      southshore = true,
    }))
    T.truthy(r.ok, T.dumpRoute(r))
    T.truthy(T.hasNode(r, "southshore_fp"), T.dumpRoute(r))
    if r.suggestion then
      local text = r.suggestion.text or ""
      T.falsy(text:lower():find("southshore", 1, true), T.dumpRoute(r))
    end
  end)

  T.it("neutral Booty Bay is usable by both factions", function()
    local a = Layover.Router.route(T.allianceWarrior({
      to = "booty bay",
      hearthReady = false,
    }))
    local h = Layover.Router.route(T.hordeWarrior({
      to = "booty bay",
      hearthReady = false,
    }))
    T.truthy(a.ok, T.dumpRoute(a))
    T.truthy(h.ok, T.dumpRoute(h))
  end)
end)
