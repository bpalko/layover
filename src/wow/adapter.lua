Layover = Layover or {}
local Adapter = {}
Layover.Adapter = Adapter

local function safeCall(fn, ...)
  if type(fn) ~= "function" then
    return nil
  end
  local ok, a, b, c, d = pcall(fn, ...)
  if not ok then
    return nil
  end
  return a, b, c, d
end

local function mapPosition(uiMapID)
  if not uiMapID or not C_Map or not C_Map.GetPlayerMapPosition then
    return nil, nil
  end
  local pos = safeCall(C_Map.GetPlayerMapPosition, uiMapID, "player")
  if not pos then
    return nil, nil
  end
  if pos.x and pos.y then
    return pos.x, pos.y
  end
  if pos.GetXY then
    return pos:GetXY()
  end
  return nil, nil
end

function Adapter.getBestMap()
  if C_Map and C_Map.GetBestMapForUnit then
    return safeCall(C_Map.GetBestMapForUnit, "player")
  end
  return nil
end

function Adapter.getUserWaypoint()
  if not C_Map or not C_Map.HasUserWaypoint or not C_Map.GetUserWaypoint then
    return nil
  end
  local has = safeCall(C_Map.HasUserWaypoint)
  if not has then
    return nil
  end
  local wp = safeCall(C_Map.GetUserWaypoint)
  if not wp then
    return nil
  end
  local x, y
  if wp.position then
    x, y = wp.position.x, wp.position.y
    if (not x or not y) and wp.position.GetXY then
      x, y = wp.position:GetXY()
    end
  end
  x = x or wp.x
  y = y or wp.y
  if not wp.uiMapID or not x or not y then
    return nil
  end
  return {
    uiMapID = wp.uiMapID,
    x = x,
    y = y,
    zx = x,
    zy = y,
    name = "Map pin",
  }
end

function Adapter.getTomTomWaypoint()
  local tom = _G.TomTom
  if not tom then
    return nil
  end
  local ok, result = pcall(function()
    local uid
    if tom.GetClosestWaypoint then
      uid = tom:GetClosestWaypoint()
    elseif tom.GetCrazyArrowWaypoint then
      uid = tom:GetCrazyArrowWaypoint()
    elseif tom.CrazyArrow and tom.CrazyArrow.uid then
      uid = tom.CrazyArrow.uid
    end
    if not uid then
      if tom.CrazyArrow and tom.CrazyArrow.waypoint then
        local wp = tom.CrazyArrow.waypoint
        local uiMapID = wp.m or wp.uiMapID or wp.map
        local x, y = wp.x, wp.y
        if uiMapID and x and y then
          return { uiMapID = uiMapID, x = x, y = y, zx = x, zy = y, name = wp.title or "TomTom waypoint" }
        end
      end
      return nil
    end
    if tom.GetWaypointInfo then
      local a, b, c, d = tom:GetWaypointInfo(uid)
      -- Classic TomTom: m, x, y or m, f, x, y
      if type(b) == "number" and b <= 1 and type(c) == "number" then
        return { uiMapID = a, x = b, y = c, zx = b, zy = c, name = "TomTom waypoint" }
      end
      if type(c) == "number" and type(d) == "number" then
        return { uiMapID = a, x = c, y = d, zx = c, zy = d, name = "TomTom waypoint" }
      end
    end
    return nil
  end)
  if ok then
    return result
  end
  return nil
end

local MAGE_SPELLS = {
  "Teleport: Stormwind",
  "Teleport: Ironforge",
  "Teleport: Darnassus",
  "Teleport: Orgrimmar",
  "Teleport: Undercity",
  "Teleport: Thunder Bluff",
}

local function spellBookHas(spellName)
  if IsPlayerSpell and C_Spell and C_Spell.GetSpellInfo then
    local info = safeCall(C_Spell.GetSpellInfo, spellName)
    if info and info.spellID and IsPlayerSpell(info.spellID) then
      return true
    end
  end
  local bookType = _G.BOOKTYPE_SPELL or "spell"
  local GetSpellBookItemName = _G.GetSpellBookItemName
  if not GetSpellBookItemName then
    return false
  end
  for i = 1, 400 do
    local name = GetSpellBookItemName(i, bookType)
    if not name then
      break
    end
    if name == spellName then
      return true
    end
  end
  return false
end

function Adapter.getKnownSpells()
  local spells = {}
  local class = Adapter.getClass()
  if class == "MAGE" then
    for i = 1, #MAGE_SPELLS do
      if spellBookHas(MAGE_SPELLS[i]) then
        spells[MAGE_SPELLS[i]] = true
      end
    end
  elseif class == "DRUID" then
    if spellBookHas("Teleport: Moonglade") then
      spells["Teleport: Moonglade"] = true
    end
  end
  return spells
end

function Adapter.getClass()
  if UnitClass then
    local _, class = UnitClass("player")
    return class
  end
  return nil
end

function Adapter.getFaction()
  if UnitFactionGroup then
    return UnitFactionGroup("player")
  end
  return nil
end

function Adapter.getBindLocation()
  if GetBindLocation then
    return GetBindLocation()
  end
  return nil
end

function Adapter.hearthReady()
  if not GetItemCooldown then
    return true
  end
  local start, duration = GetItemCooldown(6948)
  if not start or not duration or duration == 0 then
    return true
  end
  local now = GetTime and GetTime() or 0
  return (now - start) >= duration
end

function Adapter.astralRecallReady()
  if Adapter.getClass() ~= "SHAMAN" then
    return false
  end
  if GetSpellCooldown and GetSpellInfo then
    local name = GetSpellInfo("Astral Recall")
    if name then
      local start, duration = GetSpellCooldown("Astral Recall")
      if not start or not duration or duration == 0 then
        return true
      end
      local now = GetTime and GetTime() or 0
      return (now - start) >= duration
    end
  end
  return spellBookHas("Astral Recall")
end

function Adapter.getSpeedYdsPerSec()
  if GetUnitSpeed then
    local current, run = GetUnitSpeed("player")
    if current and current > 0.1 then
      return current
    end
    if run and run > 0.1 then
      -- GetUnitSpeed's second return is the current speed without moving
      -- in some clients; prefer mounted inference below if standing.
    end
  end
  local profile = {
    class = Adapter.getClass(),
    mounted60 = false,
    mounted100 = false,
  }
  if IsMounted and IsMounted() then
    local level = UnitLevel and UnitLevel("player") or 1
    if level >= 60 then
      profile.mounted100 = true
    elseif level >= 40 then
      profile.mounted60 = true
    else
      profile.mounted60 = true
    end
  else
    local level = UnitLevel and UnitLevel("player") or 1
    profile.level = level
    if profile.class == "DRUID" then
      profile.travelForm = true
    elseif profile.class == "SHAMAN" then
      profile.ghostWolf = true
    elseif profile.class == "HUNTER" then
      profile.cheetah = true
    end
  end
  return Layover.Movement.speedYdsPerSec(profile)
end

function Adapter.onTaxi()
  if UnitOnTaxi then
    return UnitOnTaxi("player") and true or false
  end
  return false
end

function Adapter.getSnapshot()
  local uiMapID = Adapter.getBestMap()
  local zx, zy = mapPosition(uiMapID)
  local wx, wy, continent
  if uiMapID and zx and zy then
    wx, wy, continent = Layover.Graph.mapToWorld(uiMapID, zx, zy)
  elseif uiMapID then
    wx, wy, continent = Layover.Graph.mapToWorld(uiMapID, 0.5, 0.5)
  end
  local zoneName = GetZoneText and GetZoneText() or nil
  local subZone = GetSubZoneText and GetSubZoneText() or nil
  if (not continent or not wx) and zoneName then
    local node = Layover.Destinations.resolve(zoneName, Adapter.getFaction())
    if node then
      wx = wx or node.wx
      wy = wy or node.wy
      continent = continent or node.continent
      uiMapID = uiMapID or node.uiMapID
    end
  end
  return {
    uiMapID = uiMapID,
    zx = zx,
    zy = zy,
    x = zx,
    y = zy,
    wx = wx,
    wy = wy,
    continent = continent,
    zoneName = zoneName,
    subZone = subZone,
    onTaxi = Adapter.onTaxi(),
    faction = Adapter.getFaction(),
    class = Adapter.getClass(),
    bindLocation = Adapter.getBindLocation(),
    hearthReady = Adapter.hearthReady(),
    astralRecallReady = Adapter.astralRecallReady(),
    spells = Adapter.getKnownSpells(),
    speedYdsPerSec = Adapter.getSpeedYdsPerSec(),
    level = UnitLevel and UnitLevel("player") or nil,
  }
end

function Adapter.characterKey()
  local name = UnitName and UnitName("player") or "Unknown"
  local realm = GetRealmName and GetRealmName() or "Realm"
  return name .. "-" .. realm
end

function Adapter.scanTaxiMap()
  local names = {}
  if not NumTaxiNodes then
    return names
  end
  local n = NumTaxiNodes() or 0
  for i = 1, n do
    local nodeType = TaxiNodeGetType and TaxiNodeGetType(i) or nil
    -- CURRENT is the node we opened; REACHABLE is a discovered destination.
    if nodeType == "CURRENT" or nodeType == "REACHABLE" or nodeType == "KNOWN" then
      local taxiName = TaxiNodeName and TaxiNodeName(i) or nil
      if taxiName then
        names[#names + 1] = taxiName
      end
    end
  end
  -- Always record the current node even if type APIs differ.
  if n > 0 and #names == 0 then
    for i = 1, n do
      local taxiName = TaxiNodeName and TaxiNodeName(i) or nil
      if taxiName then
        names[#names + 1] = taxiName
      end
    end
  end
  return names
end

function Adapter.print(msg)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cff4fc3f7Layover:|r " .. tostring(msg))
  end
end
