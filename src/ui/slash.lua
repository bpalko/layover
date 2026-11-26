Layover = Layover or {}
local Slash = {}
Layover.Slash = Slash

local HELP = [[Layover commands:
  /lo <destination>   Route to a city, dungeon, zone, or alias (sm, rfc, dm, brd)
  /lo skip            Skip the current step
  /lo clear           Clear the active route
  /lo pin             Route to the native map pin (or TomTom if no pin)
  /lo window          Toggle the checklist window
  /lo lock            Lock/unlock window dragging
  /lo help            Show this help]]

function Slash.init()
  _G.SLASH_LAYOVER1 = "/layover"
  _G.SLASH_LAYOVER2 = "/lo"
  SlashCmdList = SlashCmdList or {}
  SlashCmdList["LAYOVER"] = function(msg)
    Layover.command(msg)
  end
end

if _G.SlashCmdList or _G.DEFAULT_CHAT_FRAME or _G.CreateFrame then
  Slash.init()
end

function Layover.command(msg)
  msg = Layover.Util.trim(msg or "")
  local lower = string.lower(msg)
  if msg == "" or lower == "window" or lower == "show" or lower == "toggle" then
    if Layover.UI then
      Layover.UI.toggle()
    end
    return
  end
  if lower == "help" or lower == "?" then
    Layover.Adapter.print(HELP)
    return
  end
  if lower == "skip" or lower == "next" then
    Layover.skipStep()
    return
  end
  if lower == "clear" or lower == "reset" or lower == "stop" then
    Layover.clearRoute()
    return
  end
  if lower == "lock" then
    if Layover.UI then
      Layover.UI.locked = not Layover.UI.locked
      Layover.Adapter.print(Layover.UI.locked and "Window locked." or "Window unlocked.")
    end
    return
  end
  if lower == "pin" or lower == "waypoint" or lower == "tomtom" then
    Layover.routeFromExternalWaypoint()
    return
  end
  Layover.routeTo(msg, { source = "slash" })
end
