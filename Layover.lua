Layover = Layover or {}

function Layover.buildQuery(toSpec, opts)
  opts = opts or {}
  local snap = (Layover.Adapter and Layover.Adapter.getSnapshot and Layover.Adapter.getSnapshot()) or {}
  local from = opts.from or {
    uiMapID = snap.uiMapID,
    zx = snap.zx,
    zy = snap.zy,
    wx = snap.wx,
    wy = snap.wy,
    continent = snap.continent,
    name = "You",
  }
  local known = {}
  if Layover.Saved then
    known = Layover.Saved.getKnownFlights()
  end
  if opts.knownFlights then
    known = opts.knownFlights
  end
  return {
    from = from,
    to = toSpec,
    faction = opts.faction or snap.faction,
    class = opts.class or snap.class,
    knownFlights = known,
    speedYdsPerSec = opts.speedYdsPerSec or snap.speedYdsPerSec,
    hearth = opts.hearth or {
      bind = snap.bindLocation,
      ready = snap.hearthReady,
    },
    spells = opts.spells or snap.spells,
    astralRecallReady = opts.astralRecallReady,
    preferDiscover = opts.preferDiscover,
  }
end

function Layover.routeTo(toSpec, opts)
  opts = opts or {}
  if type(toSpec) == "string" then
    local node, score = Layover.Destinations.resolve(toSpec, (opts.faction or (Layover.Adapter and Layover.Adapter.getFaction())))
    if not node or score < 38 then
      if Layover.Adapter then
        Layover.Adapter.print("Unknown destination: " .. tostring(toSpec) .. " — try /lo help")
      end
      return { ok = false, error = "unknown_destination", query = toSpec }
    end
    toSpec = { nodeId = node.id, name = node.name }
  end
  local query = Layover.buildQuery(toSpec, opts)
  local result = Layover.Router.route(query)
  if result.ok then
    Layover.state = Layover.Steps.new(result)
    if Layover.UI then
      Layover.UI.show()
      Layover.UI.refresh()
    end
    if opts.source ~= "rediscover" and Layover.Adapter and result.to then
      local extra = ""
      if result.suggestion then
        extra = "  (" .. result.suggestion.text .. ")"
      end
      Layover.Adapter.print("Route to " .. result.to.name .. " — " .. result.eta .. extra)
    end
  else
    if Layover.Adapter then
      Layover.Adapter.print("No route found.")
    end
  end
  return result
end

function Layover.routeFromExternalWaypoint()
  local wp = Layover.Adapter.getUserWaypoint()
  if wp then
    return Layover.routeTo({
      uiMapID = wp.uiMapID,
      zx = wp.zx or wp.x,
      zy = wp.zy or wp.y,
      name = "Map pin",
    }, { source = "waypoint" })
  end
  local tom = Layover.Adapter.getTomTomWaypoint()
  if tom then
    return Layover.routeTo({
      uiMapID = tom.uiMapID,
      zx = tom.zx or tom.x,
      zy = tom.zy or tom.y,
      name = tom.name or "TomTom waypoint",
    }, { source = "tomtom" })
  end
  Layover.Adapter.print("No map pin or TomTom waypoint found.")
  return { ok = false, error = "no_waypoint" }
end

function Layover.skipStep()
  if not Layover.state or not Layover.state.ok then
    return
  end
  Layover.Steps.skip(Layover.state)
  if Layover.UI then
    Layover.UI.refresh()
  end
  if Layover.state.complete then
    Layover.Adapter.print("Route cleared.")
  end
end

function Layover.clearRoute()
  if Layover.state then
    Layover.Steps.clear(Layover.state)
  end
  Layover.state = nil
  if Layover.UI then
    Layover.UI.refresh()
  end
  if Layover.Adapter then
    Layover.Adapter.print("Route cleared.")
  end
end

-- TOC files after this one (UI/events) call their init from PLAYER_LOGIN /
-- ADDON_LOADED. Graph is built lazily on first route as well.
if Layover.Graph then
  Layover.Graph.build()
end
