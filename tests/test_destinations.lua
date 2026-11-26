local T = ...

T.describe("destinations", function()
  T.it("resolves Scarlet Monastery aliases", function()
    for _, q in ipairs({ "sm", "SM", "scarlet monastery", "Scarlet Monastery", "scarlet" }) do
      local node, score = Layover.Destinations.resolve(q, "Alliance")
      T.truthy(node, q)
      T.eq(node.id, "sm", q)
      T.gt(score, 50, q)
    end
  end)

  T.it("resolves Undercity and Ruins of Lordaeron", function()
    local uc = Layover.Destinations.resolve("undercity", "Horde")
    T.eq(uc.id, "undercity")
    local ruins = Layover.Destinations.resolve("ruins of lordaeron", "Alliance")
    T.eq(ruins.id, "ruins_of_lordaeron")
    local ruins2 = Layover.Destinations.resolve("lordaeron", "Alliance")
    T.eq(ruins2.id, "ruins_of_lordaeron")
  end)

  T.it("resolves dungeon / raid aliases", function()
    local cases = {
      { "rfc", "rfc" },
      { "ragefire chasm", "rfc" },
      { "dm", "deadmines" },
      { "deadmines", "deadmines" },
      { "vc", "deadmines" },
      { "brd", "brd" },
      { "strat", "strat" },
      { "stratholme", "strat" },
      { "scholo", "scholo" },
      { "scholomance", "scholo" },
      { "sfk", "sfk" },
      { "bfd", "bfd" },
      { "gnomer", "gnomer" },
      { "zf", "zf" },
      { "mara", "mara" },
      { "wc", "wc" },
      { "stocks", "stockades" },
      { "dire maul", "dire_maul" },
      { "ony", "onyxia" },
      { "mc", "mc" },
      { "bwl", "bwl" },
      { "zg", "zg" },
      { "naxx", "naxx" },
      { "aq40", "aq40" },
    }
    for i = 1, #cases do
      local node = Layover.Destinations.resolve(cases[i][1], "Alliance")
      T.truthy(node, cases[i][1])
      T.eq(node.id, cases[i][2], cases[i][1])
    end
  end)

  T.it("resolves cities and common shortcuts", function()
    T.eq(Layover.Destinations.resolve("sw", "Alliance").id, "stormwind")
    T.eq(Layover.Destinations.resolve("if", "Alliance").id, "ironforge")
    T.eq(Layover.Destinations.resolve("org", "Horde").id, "orgrimmar")
    T.eq(Layover.Destinations.resolve("tb", "Horde").id, "thunder_bluff")
    T.eq(Layover.Destinations.resolve("uc", "Horde").id, "undercity")
  end)

  T.it("uses faction-aware zone names", function()
    T.eq(Layover.Destinations.resolve("hillsbrad", "Alliance").id, "southshore")
    T.eq(Layover.Destinations.resolve("hillsbrad", "Horde").id, "tarren_mill")
    T.eq(Layover.Destinations.resolve("ashenvale", "Alliance").id, "astranaar")
    T.eq(Layover.Destinations.resolve("ashenvale", "Horde").id, "splintertree")
  end)

  T.it("fuzzy-matches typos", function()
    local node = Layover.Destinations.resolve("ironforeg", "Alliance")
    T.truthy(node)
    T.eq(node.id, "ironforge")
  end)

  T.it("search returns ranked suggestions", function()
    local results = Layover.Destinations.search("scar", "Alliance", 5)
    T.gt(#results, 0)
    T.eq(results[1].node.id, "sm")
  end)

  T.it("resolves a coordinate waypoint", function()
    local node = Layover.Destinations.resolve({ uiMapID = 1429, x = 0.42, y = 0.66, name = "Pin" })
    T.truthy(node)
    T.eq(node.uiMapID, 1429)
    T.eq(node.kind, "coord")
  end)

  T.it("resolves hearth bind strings", function()
    T.eq(Layover.Destinations.resolveBind("Stormwind City").id, "stormwind")
    T.eq(Layover.Destinations.resolveBind("Southshore").id, "southshore")
    T.eq(Layover.Destinations.resolveBind("The Lion's Pride Inn").id, "goldshire")
  end)

  T.it("elwynn forest alias points at goldshire", function()
    T.eq(Layover.Destinations.resolve("elwynn forest").id, "goldshire")
  end)
end)
