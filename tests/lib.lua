local Lib = {}

Lib.passed = 0
Lib.failed = 0
Lib.errors = {}
Lib.currentFile = ""

function Lib.describe(name, fn)
  local prev = Lib.currentFile
  Lib.currentFile = name
  fn()
  Lib.currentFile = prev
end

function Lib.it(name, fn)
  local ok, err = pcall(fn)
  if ok then
    Lib.passed = Lib.passed + 1
  else
    Lib.failed = Lib.failed + 1
    local msg = Lib.currentFile .. " :: " .. name .. "\n    " .. tostring(err)
    Lib.errors[#Lib.errors + 1] = msg
    print("FAIL  " .. msg)
  end
end

function Lib.eq(actual, expected, msg)
  if actual ~= expected then
    error((msg or "eq") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
  end
end

function Lib.neq(actual, unexpected, msg)
  if actual == unexpected then
    error((msg or "neq") .. ": did not expect " .. tostring(unexpected), 2)
  end
end

function Lib.truthy(value, msg)
  if not value then
    error(msg or "expected truthy value", 2)
  end
end

function Lib.falsy(value, msg)
  if value then
    error((msg or "expected falsy") .. ": got " .. tostring(value), 2)
  end
end

function Lib.gt(actual, min, msg)
  if actual <= min then
    error((msg or "gt") .. ": expected " .. tostring(actual) .. " > " .. tostring(min), 2)
  end
end

function Lib.lt(actual, max, msg)
  if actual >= max then
    error((msg or "lt") .. ": expected " .. tostring(actual) .. " < " .. tostring(max), 2)
  end
end

function Lib.contains(haystack, needle, msg)
  if type(haystack) == "table" then
    for i = 1, #haystack do
      if haystack[i] == needle then
        return
      end
    end
    error((msg or "contains") .. ": missing " .. tostring(needle), 2)
    return
  end
  haystack = tostring(haystack):lower()
  needle = tostring(needle):lower()
  if not haystack:find(needle, 1, true) then
    error((msg or "contains") .. ": " .. tostring(needle) .. " not in " .. haystack, 2)
  end
end

function Lib.dumpRoute(result)
  if not result then
    return "(nil result)"
  end
  if not result.ok then
    return "ok=false error=" .. tostring(result.error)
  end
  return Layover.Router.describe(result)
end

function Lib.stepModes(result)
  local modes = {}
  for i = 1, #(result.steps or {}) do
    modes[i] = result.steps[i].mode
  end
  return table.concat(modes, ",")
end

function Lib.hasMode(result, mode)
  return Layover.Router.pathContainsMode(result, mode)
end

function Lib.hasNode(result, nodeId)
  return Layover.Router.pathContainsNode(result, nodeId)
end

function Lib.starterAllianceFlights(withSouthshore)
  local known = {
    stormwind_fp = true,
    sentinel_hill_fp = true,
    lakeshire_fp = true,
    darkshire_fp = true,
    ironforge_fp = true,
    thelsamar_fp = true,
    menethil_fp = true,
  }
  if withSouthshore then
    known.southshore_fp = true
  end
  return known
end

function Lib.starterHordeFlights()
  return {
    orgrimmar_fp = true,
    crossroads_fp = true,
    ratchet_fp = true,
    undercity_fp = true,
    sepulcher_fp = true,
    gromgol_fp = true,
  }
end

function Lib.goldshire()
  return { uiMapID = 1429, zx = 0.42, zy = 0.66, name = "Goldshire" }
end

function Lib.allianceWarrior(opts)
  opts = opts or {}
  return {
    from = opts.from or Lib.goldshire(),
    to = opts.to,
    faction = "Alliance",
    class = opts.class or "WARRIOR",
    knownFlights = opts.knownFlights or Lib.starterAllianceFlights(opts.southshore),
    speedYdsPerSec = opts.speedYdsPerSec or 7,
    hearth = {
      bind = opts.bind or "Stormwind City",
      ready = opts.hearthReady and true or false,
    },
    spells = opts.spells or {},
    preferDiscover = opts.preferDiscover,
  }
end

function Lib.allianceMage(opts)
  opts = opts or {}
  opts.class = "MAGE"
  opts.spells = opts.spells or {
    ["Teleport: Stormwind"] = true,
    ["Teleport: Ironforge"] = true,
    ["Teleport: Darnassus"] = true,
  }
  return Lib.allianceWarrior(opts)
end

function Lib.hordeWarrior(opts)
  opts = opts or {}
  return {
    from = opts.from or { uiMapID = 1454, zx = 0.52, zy = 0.64, name = "Orgrimmar" },
    to = opts.to,
    faction = "Horde",
    class = opts.class or "WARRIOR",
    knownFlights = opts.knownFlights or Lib.starterHordeFlights(),
    speedYdsPerSec = opts.speedYdsPerSec or 7,
    hearth = {
      bind = opts.bind or "Orgrimmar",
      ready = opts.hearthReady and true or false,
    },
    spells = opts.spells or {},
  }
end

return Lib
