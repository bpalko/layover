local T = ...

T.describe("router: Elwynn to Ruins / SM", function()
  T.it("Alliance warrior reaches Ruins of Lordaeron without Southshore", function()
    local q = T.allianceWarrior({ to = "ruins of lordaeron", hearthReady = false })
    local r = Layover.Router.route(q)
    T.truthy(r.ok, T.dumpRoute(r))
    T.gt(#r.steps, 1, T.dumpRoute(r))
    T.gt(r.totalSeconds, 60, T.dumpRoute(r))
    -- Should use the tram + northern flights rather than swimming the ocean.
    T.truthy(T.hasMode(r, "tram") or T.hasNode(r, "ironforge_fp") or T.hasNode(r, "menethil_fp"), T.dumpRoute(r))
    T.falsy(T.hasMode(r, "zeppelin"), T.dumpRoute(r))
    T.falsy(T.hasNode(r, "org_zeppelin"), T.dumpRoute(r))
    T.falsy(T.hasNode(r, "tarren_mill_fp"), T.dumpRoute(r))
  end)

  T.it("Alliance warrior with Southshore FP is faster to Ruins", function()
    local without = Layover.Router.route(T.allianceWarrior({
      to = "ruins of lordaeron",
      hearthReady = false,
      southshore = false,
    }))
    local with = Layover.Router.route(T.allianceWarrior({
      to = "ruins of lordaeron",
      hearthReady = false,
      southshore = true,
    }))
    T.truthy(without.ok, T.dumpRoute(without))
    T.truthy(with.ok, T.dumpRoute(with))
    T.truthy(T.hasNode(with, "southshore_fp"), T.dumpRoute(with))
    T.lt(with.totalSeconds, without.totalSeconds, string.format(
      "with SS %s vs without %s\nWITH:\n%s\nWITHOUT:\n%s",
      tostring(with.totalSeconds), tostring(without.totalSeconds),
      T.dumpRoute(with), T.dumpRoute(without)
    ))
  end)

  T.it("unknown Southshore is suggested as a discovery", function()
    local r = Layover.Router.route(T.allianceWarrior({
      to = "ruins of lordaeron",
      hearthReady = false,
      southshore = false,
    }))
    T.truthy(r.ok, T.dumpRoute(r))
    T.truthy(r.suggestion, T.dumpRoute(r))
    T.contains(r.suggestion.text, "Southshore", T.dumpRoute(r))
    T.gt(r.suggestion.savedSeconds, 30)
  end)

  T.it("hearthstone to Southshore beats walking from Elwynn", function()
    local noHearth = Layover.Router.route(T.allianceWarrior({
      to = "ruins of lordaeron",
      hearthReady = false,
      bind = "Stormwind City",
    }))
    local hearth = Layover.Router.route(T.allianceWarrior({
      to = "ruins of lordaeron",
      hearthReady = true,
      bind = "Southshore",
    }))
    T.truthy(hearth.ok, T.dumpRoute(hearth))
    T.truthy(T.hasMode(hearth, "hearth"), T.dumpRoute(hearth))
    T.lt(hearth.totalSeconds, noHearth.totalSeconds, T.dumpRoute(hearth) .. "\n" .. T.dumpRoute(noHearth))
  end)

  T.it("hearth on cooldown is not used", function()
    local r = Layover.Router.route(T.allianceWarrior({
      to = "stormwind",
      hearthReady = false,
      bind = "Stormwind City",
    }))
    T.truthy(r.ok, T.dumpRoute(r))
    T.falsy(T.hasMode(r, "hearth"), T.dumpRoute(r))
  end)

  T.it("Mage teleport to Ironforge skips the tram", function()
    local warrior = Layover.Router.route(T.allianceWarrior({
      to = "ruins of lordaeron",
      hearthReady = false,
    }))
    local mage = Layover.Router.route(T.allianceMage({
      to = "ruins of lordaeron",
      hearthReady = false,
    }))
    T.truthy(mage.ok, T.dumpRoute(mage))
    T.truthy(T.hasMode(mage, "teleport"), T.dumpRoute(mage))
    T.falsy(T.hasMode(mage, "tram"), T.dumpRoute(mage))
    T.lt(mage.totalSeconds, warrior.totalSeconds, T.dumpRoute(mage) .. "\n" .. T.dumpRoute(warrior))
  end)

  T.it("Alliance warrior reaches Scarlet Monastery", function()
    local r = Layover.Router.route(T.allianceWarrior({
      to = "sm",
      hearthReady = false,
      southshore = true,
    }))
    T.truthy(r.ok, T.dumpRoute(r))
    T.truthy(T.hasNode(r, "southshore_fp") or T.hasNode(r, "menethil_fp"), T.dumpRoute(r))
    T.eq(r.to.id, "sm")
    T.falsy(T.hasMode(r, "zeppelin"), T.dumpRoute(r))
  end)

  T.it("coordinate waypoint in Tirisfal routes from Elwynn", function()
    local sm = Layover.Graph.getNode("sm")
    local r = Layover.Router.route(T.allianceWarrior({
      to = { uiMapID = sm.uiMapID, zx = sm.zx, zy = sm.zy, name = "Map pin" },
      hearthReady = false,
      southshore = true,
    }))
    T.truthy(r.ok, T.dumpRoute(r))
    T.eq(r.to.kind, "coord")
    T.gt(#r.steps, 1, T.dumpRoute(r))
  end)
end)

T.describe("router: cross-continent", function()
  T.it("Alliance Elwynn to Darnassus uses boats and/or Rut'theran flight", function()
    local r = Layover.Router.route(T.allianceWarrior({
      to = "darnassus",
      hearthReady = false,
      knownFlights = {
        stormwind_fp = true,
        ironforge_fp = true,
        menethil_fp = true,
        auberdine_fp = true,
        ruttheran_fp = true,
        darnassus_fp = true,
      },
    }))
    T.truthy(r.ok, T.dumpRoute(r))
    T.truthy(T.hasMode(r, "boat") or T.hasNode(r, "auberdine_fp") or T.hasNode(r, "ruttheran_fp"), T.dumpRoute(r))
    T.truthy(T.hasMode(r, "portal") or T.hasNode(r, "darnassus") or T.hasNode(r, "darnassus_fp"), T.dumpRoute(r))
    T.falsy(T.hasMode(r, "zeppelin"), T.dumpRoute(r))
    T.lt(r.totalSeconds, 35 * 60, "Teldrassil should use the town portal, not a long walk\n" .. T.dumpRoute(r))
  end)

  T.it("Alliance Westfall to Ratchet uses Booty Bay boat", function()
    local r = Layover.Router.route(T.allianceWarrior({
      from = { uiMapID = 1436, zx = 0.56, zy = 0.53, name = "Sentinel Hill" },
      to = "ratchet",
      hearthReady = false,
    }))
    T.truthy(r.ok, T.dumpRoute(r))
    T.truthy(T.hasMode(r, "boat"), T.dumpRoute(r))
    T.truthy(T.hasNode(r, "booty_bay_dock") or T.hasNode(r, "ratchet_dock"), T.dumpRoute(r))
  end)

  T.it("Horde Orgrimmar to Booty Bay crosses by zeppelin or the Ratchet boat", function()
    local r = Layover.Router.route(T.hordeWarrior({ to = "booty bay" }))
    T.truthy(r.ok, T.dumpRoute(r))
    T.truthy(T.hasMode(r, "zeppelin") or T.hasMode(r, "boat"), T.dumpRoute(r))
    T.falsy(T.hasMode(r, "tram"), T.dumpRoute(r))
  end)

  T.it("Horde Orgrimmar to Undercity uses the zeppelin", function()
    local r = Layover.Router.route(T.hordeWarrior({ to = "undercity", hearthReady = false }))
    T.truthy(r.ok, T.dumpRoute(r))
    T.truthy(T.hasMode(r, "zeppelin"), T.dumpRoute(r))
    T.falsy(T.hasMode(r, "tram"), T.dumpRoute(r))
  end)

  T.it("Horde Orgrimmar to Scarlet Monastery uses zeppelin to Undercity", function()
    local r = Layover.Router.route(T.hordeWarrior({ to = "sm", hearthReady = false }))
    T.truthy(r.ok, T.dumpRoute(r))
    T.truthy(T.hasMode(r, "zeppelin") or T.hasNode(r, "undercity") or T.hasNode(r, "uc_zeppelin"), T.dumpRoute(r))
    T.falsy(T.hasMode(r, "tram"), T.dumpRoute(r))
  end)

  T.it("Deeprun Tram is used for Alliance Stormwind to Ironforge", function()
    local r = Layover.Router.route(T.allianceWarrior({
      from = { nodeId = "stormwind" },
      to = "ironforge",
      hearthReady = false,
    }))
    T.truthy(r.ok, T.dumpRoute(r))
    T.truthy(T.hasMode(r, "tram"), T.dumpRoute(r))
  end)
end)

T.describe("router: class abilities", function()
  T.it("Druid Moonglade teleport is used when known", function()
    local q = T.allianceWarrior({
      to = "moonglade",
      hearthReady = false,
      class = "DRUID",
      spells = { ["Teleport: Moonglade"] = true },
    })
    local r = Layover.Router.route(q)
    T.truthy(r.ok, T.dumpRoute(r))
    T.truthy(T.hasMode(r, "teleport"), T.dumpRoute(r))
  end)

  T.it("Shaman Astral Recall behaves like a hearth", function()
    local q = T.allianceWarrior({
      to = "ruins of lordaeron",
      hearthReady = false,
      bind = "Southshore",
      class = "SHAMAN",
    })
    q.astralRecallReady = true
    local r = Layover.Router.route(q)
    T.truthy(r.ok, T.dumpRoute(r))
    T.truthy(T.hasMode(r, "astral_recall"), T.dumpRoute(r))
  end)

  T.it("does not invent Warlock summons", function()
    local r = Layover.Router.route(T.allianceWarrior({
      to = "orgrimmar",
      class = "WARLOCK",
      hearthReady = false,
    }))
    T.truthy(r.ok, T.dumpRoute(r))
    local desc = T.dumpRoute(r):lower()
    T.falsy(desc:find("summon", 1, true), desc)
    T.falsy(desc:find("ritual", 1, true), desc)
  end)
end)
