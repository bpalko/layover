Layover = Layover or {}
local Graph = {}
Layover.Graph = Graph

local function ensureBuilt()
  if Graph._built then
    return
  end
  Graph._built = true
  Graph.nodes = Layover.Data.nodes
  Graph.edges = Layover.Data.edges
  Graph.zones = Layover.Data.zones
  Graph.taxiIndex = Layover.Data.nodesByTaxi
  Graph.aliasIndex = Layover.Data.nodesByAlias

  local outgoing = {}
  for id in pairs(Graph.nodes) do
    outgoing[id] = {}
  end
  for i = 1, #Graph.edges do
    local e = Graph.edges[i]
    local list = outgoing[e.from]
    if list then
      list[#list + 1] = e
    end
  end
  Graph.outgoing = outgoing
end

function Graph.build()
  Graph._built = false
  ensureBuilt()
  return Graph
end

function Graph.getNode(id)
  ensureBuilt()
  return Graph.nodes[id]
end

function Graph.getNodes()
  ensureBuilt()
  return Graph.nodes
end

function Graph.getEdges()
  ensureBuilt()
  return Graph.edges
end

function Graph.getOutgoing(id)
  ensureBuilt()
  return Graph.outgoing[id] or {}
end

function Graph.getZone(uiMapID)
  ensureBuilt()
  return Graph.zones[uiMapID]
end

function Graph.mapToWorld(uiMapID, zx, zy)
  ensureBuilt()
  local wx, wy = Layover.Data.worldOf(uiMapID, zx, zy)
  local zone = Graph.zones[uiMapID]
  return wx, wy, zone and zone.continent or nil
end

function Graph.makeCoordNode(id, uiMapID, zx, zy, name)
  ensureBuilt()
  local wx, wy, continent = Graph.mapToWorld(uiMapID, zx, zy)
  local zone = Graph.zones[uiMapID]
  return {
    id = id,
    name = name or (zone and zone.name) or ("Map " .. tostring(uiMapID)),
    kind = "coord",
    faction = "Neutral",
    uiMapID = uiMapID,
    zx = zx,
    zy = zy,
    wx = wx,
    wy = wy,
    continent = continent or "EK",
    virtual = true,
  }
end

function Graph.nodeFromTaxiName(taxiName)
  ensureBuilt()
  if not taxiName then
    return nil
  end
  local id = Graph.taxiIndex[Layover.Util.normalize(taxiName)]
  if id then
    return Graph.nodes[id]
  end
  -- Taxi names are "Stormwind, Elwynn" — try the city token.
  local city = taxiName:match("^([^,]+)")
  if city then
    id = Graph.aliasIndex[Layover.Util.normalize(city)]
    if id then
      local node = Graph.nodes[id]
      if node and node.kind == "flight" then
        return node
      end
      if node then
        local fp = Graph.nodes[id .. "_fp"]
        if fp then
          return fp
        end
      end
    end
  end
  return nil
end

function Graph.isFlightNode(node)
  return node and node.kind == "flight"
end

function Graph.factionAllowed(edgeOrNodeFaction, playerFaction)
  if not edgeOrNodeFaction or edgeOrNodeFaction == "Neutral" then
    return true
  end
  if not playerFaction then
    return true
  end
  return edgeOrNodeFaction == playerFaction
end

function Graph.iterFlightNodes()
  ensureBuilt()
  return function(_, id)
    local k, node = next(Graph.nodes, id)
    while k do
      if node.kind == "flight" then
        return k, node
      end
      k, node = next(Graph.nodes, k)
    end
  end, nil, nil
end
