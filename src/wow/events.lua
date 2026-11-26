Layover = Layover or {}
local Events = {}
Layover.Events = Events

local ACCUM = 0
local TICK = 0.4
local wasOnTaxi = false

local function routeToSpec(spec, source)
  if not spec then
    return
  end
  local result = Layover.routeTo(spec, { source = source })
  if result and result.ok then
    Layover.Adapter.print("Routing to " .. (result.to and result.to.name or "destination") .. " — " .. (result.eta or ""))
  elseif result and result.error == "unknown_destination" then
    Layover.Adapter.print("Unknown destination.")
  elseif result then
    Layover.Adapter.print("No route found.")
  end
  return result
end

function Events.onUserWaypointUpdated()
  local wp = Layover.Adapter.getUserWaypoint()
  if not wp then
    return
  end
  routeToSpec({
    uiMapID = wp.uiMapID,
    zx = wp.zx or wp.x,
    zy = wp.zy or wp.y,
    name = "Map pin",
  }, "waypoint")
end

function Events.onTaxiMapOpened()
  local names = Layover.Adapter.scanTaxiMap()
  local added = Layover.Saved.rememberTaxiNames(names)
  if added > 0 then
    Layover.Adapter.print("Recorded " .. added .. " flight path(s) for this character.")
    if Layover.state and Layover.state.ok and not Layover.state.complete then
      -- Recompute with the newly discovered node.
      if Layover.state.to then
        Layover.routeTo({
          nodeId = (not Layover.state.to.virtual) and Layover.state.to.id or nil,
          uiMapID = Layover.state.to.uiMapID,
          zx = Layover.state.to.zx,
          zy = Layover.state.to.zy,
          name = Layover.state.to.name,
        }, "rediscover")
      end
    end
  end
end

function Events.tick(elapsed)
  ACCUM = ACCUM + (elapsed or 0)
  if ACCUM < TICK then
    return
  end
  ACCUM = 0
  if not Layover.state or not Layover.state.ok or Layover.state.complete then
    return
  end
  local snap = Layover.Adapter.getSnapshot()
  if wasOnTaxi and not snap.onTaxi then
    snap.taxiEndedAt = Layover.state.steps[Layover.state.currentIndex] and Layover.state.steps[Layover.state.currentIndex].toId
  end
  wasOnTaxi = snap.onTaxi
  local before = Layover.state.currentIndex
  Layover.Steps.advance(Layover.state, snap)
  if Layover.state.complete then
    Layover.Adapter.print("Arrived at " .. (Layover.state.to and Layover.state.to.name or "destination") .. ".")
    if Layover.UI then
      Layover.UI.refresh()
    end
    return
  end
  if Layover.state.currentIndex ~= before and Layover.UI then
    Layover.UI.refresh()
  end
end

function Events.init()
  if not CreateFrame then
    return
  end
  local f = CreateFrame("Frame", "LayoverEventFrame")
  f:RegisterEvent("ADDON_LOADED")
  f:RegisterEvent("PLAYER_LOGIN")
  f:RegisterEvent("PLAYER_ENTERING_WORLD")
  f:RegisterEvent("TAXIMAP_OPENED")
  f:RegisterEvent("ZONE_CHANGED")
  f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
  f:RegisterEvent("ZONE_CHANGED_INDOORS")
  f:RegisterEvent("PLAYER_CONTROL_GAINED")
  pcall(function()
    f:RegisterEvent("USER_WAYPOINT_UPDATED")
  end)
  f:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "Layover" then
      Layover.Saved.init()
    elseif event == "PLAYER_LOGIN" then
      Layover.Graph.build()
      if Layover.UI then
        Layover.UI.init()
      end
    elseif event == "USER_WAYPOINT_UPDATED" then
      Events.onUserWaypointUpdated()
    elseif event == "TAXIMAP_OPENED" then
      Events.onTaxiMapOpened()
    elseif event == "ZONE_CHANGED" or event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED_INDOORS" or event == "PLAYER_CONTROL_GAINED" or event == "PLAYER_ENTERING_WORLD" then
      Events.tick(TICK)
    end
  end)
  f:SetScript("OnUpdate", function(_, elapsed)
    Events.tick(elapsed)
  end)
  Events.frame = f
end

if _G.CreateFrame then
  Events.init()
end
