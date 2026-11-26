Layover = Layover or {}
local Saved = {}
Layover.Saved = Saved

local function db()
  if type(_G.LayoverDB) ~= "table" then
    _G.LayoverDB = {}
  end
  local root = _G.LayoverDB
  root.chars = root.chars or {}
  root.ui = root.ui or {}
  root.settings = root.settings or {}
  return root
end

local function char()
  local root = db()
  local key = "offline"
  if Layover.Adapter and Layover.Adapter.characterKey then
    key = Layover.Adapter.characterKey()
  end
  root.chars[key] = root.chars[key] or {
    discoveredFlights = {},
  }
  return root.chars[key]
end

function Saved.init()
  db()
  char()
end

function Saved.getKnownFlights()
  local c = char()
  return c.discoveredFlights or {}
end

function Saved.rememberTaxiNames(names)
  local c = char()
  c.discoveredFlights = c.discoveredFlights or {}
  local added = 0
  for i = 1, #(names or {}) do
    local taxiName = names[i]
    local node = Layover.Graph.nodeFromTaxiName(taxiName)
    if node then
      if not c.discoveredFlights[node.id] then
        added = added + 1
      end
      c.discoveredFlights[node.id] = true
      c.discoveredFlights[taxiName] = true
    else
      c.discoveredFlights[taxiName] = true
    end
  end
  return added
end

function Saved.isFlightKnown(idOrName)
  local known = Saved.getKnownFlights()
  if known[idOrName] then
    return true
  end
  local node = Layover.Graph.getNode(idOrName) or Layover.Graph.nodeFromTaxiName(idOrName)
  return node and known[node.id] and true or false
end

function Saved.getUI()
  return db().ui
end

function Saved.setUIPoint(point, x, y)
  local ui = db().ui
  ui.point = point
  ui.x = x
  ui.y = y
end

function Saved.settings()
  return db().settings
end
