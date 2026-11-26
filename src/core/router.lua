Layover = Layover or {}
local Router = {}
Layover.Router = Router

local START_ID = "__start"
local GOAL_ID = "__goal"

local function ensure()
  if not Layover.Graph._built then
    Layover.Graph.build()
  end
end

local function nodeUsable(node, playerFaction)
  if not node then
    return false
  end
  return Layover.Graph.factionAllowed(node.faction, playerFaction)
end

local function edgeUsable(edge, playerFaction)
  return Layover.Graph.factionAllowed(edge.faction, playerFaction)
end

local function flightAllowed(edge, known, allowDiscover, playerFaction)
  if edge.mode ~= "flight" then
    return edgeUsable(edge, playerFaction)
  end
  if not edgeUsable(edge, playerFaction) then
    return false
  end
  if not known[edge.from] then
    return false
  end
  if known[edge.to] then
    return true
  end
  return allowDiscover == true
end

local function addAdj(adj, edge)
  local list = adj[edge.from]
  if not list then
    list = {}
    adj[edge.from] = list
  end
  list[#list + 1] = edge
end

local function groundEdge(fromId, toId, fromNode, toNode, speed)
  local dist = Layover.Movement.nodeDistance(fromNode, toNode)
  if dist == math.huge then
    return nil
  end
  local pathing = Layover.Movement.pathingMultiplier(fromNode, toNode)
  return {
    from = fromId,
    to = toId,
    mode = "ground",
    seconds = Layover.Movement.groundSeconds(dist, speed, pathing),
    faction = "Neutral",
  }
end

local function cloneNode(node, id)
  local copy = Layover.Util.shallowCopy(node)
  copy.id = id or node.id
  return copy
end

local function collectKnown(query)
  local known = {}
  local src = query.knownFlights or {}
  -- Accept both a set of ids and a list of taxi names / ids.
  local n = #src
  if n > 0 then
    for i = 1, n do
      local token = src[i]
      if type(token) == "string" then
        known[token] = true
        local node = Layover.Graph.getNode(token) or Layover.Graph.nodeFromTaxiName(token)
        if node then
          known[node.id] = true
        end
      end
    end
  end
  for k, v in pairs(src) do
    if type(k) == "string" and v then
      known[k] = true
      local node = Layover.Graph.getNode(k) or Layover.Graph.nodeFromTaxiName(k)
      if node then
        known[node.id] = true
      end
    end
  end
  return known
end

local function resolveEndpoint(spec, faction, fallbackName)
  if not spec then
    return nil
  end
  if type(spec) == "string" then
    return Layover.Destinations.resolve(spec, faction)
  end
  if spec.nodeId then
    return Layover.Graph.getNode(spec.nodeId)
  end
  if spec.uiMapID then
    return Layover.Graph.makeCoordNode(
      spec.id or fallbackName,
      spec.uiMapID,
      spec.zx or spec.x or 0.5,
      spec.zy or spec.y or 0.5,
      spec.name
    )
  end
  if spec.wx and spec.wy then
    return {
      id = spec.id or fallbackName,
      name = spec.name or "Point",
      kind = "coord",
      faction = "Neutral",
      uiMapID = spec.uiMapID,
      zx = spec.zx or 0.5,
      zy = spec.zy or 0.5,
      wx = spec.wx,
      wy = spec.wy,
      continent = spec.continent or "EK",
      virtual = true,
    }
  end
  if spec.name or spec.query then
    return Layover.Destinations.resolve(spec.name or spec.query, faction)
  end
  return nil
end

local function addAbilityEdges(adj, nodes, query, startNode)
  local faction = query.faction
  local hearth = query.hearth or {}
  local bindName = hearth.bind or query.bindLocation
  local bindNode = bindName and Layover.Destinations.resolveBind(bindName)
  if hearth.ready and bindNode and nodeUsable(bindNode, faction) then
    addAdj(adj, {
      from = START_ID,
      to = bindNode.id,
      mode = "hearth",
      seconds = Layover.Movement.HEARTH_CAST,
      faction = "Neutral",
      label = "Hearthstone to " .. bindNode.name,
    })
  end
  if query.class == "SHAMAN" and query.astralRecallReady and bindNode and nodeUsable(bindNode, faction) then
    addAdj(adj, {
      from = START_ID,
      to = bindNode.id,
      mode = "astral_recall",
      seconds = Layover.Movement.TELEPORT_CAST,
      faction = "Neutral",
      label = "Astral Recall to " .. bindNode.name,
    })
  end
  local spells = query.spells or {}
  if query.class == "MAGE" then
    for spell, nodeId in pairs(Layover.Data.mageTeleports) do
      if spells[spell] or spells[nodeId] then
        local dest = Layover.Graph.getNode(nodeId)
        if dest and nodeUsable(dest, faction) then
          addAdj(adj, {
            from = START_ID,
            to = dest.id,
            mode = "teleport",
            seconds = Layover.Movement.TELEPORT_CAST,
            faction = faction or "Neutral",
            label = "Teleport to " .. dest.name,
            spell = spell,
          })
        end
      end
    end
  end
  if query.class == "DRUID" and (spells["Teleport: Moonglade"] or spells.moonglade) then
    local dest = Layover.Graph.getNode("moonglade")
    if dest then
      addAdj(adj, {
        from = START_ID,
        to = dest.id,
        mode = "teleport",
        seconds = Layover.Movement.TELEPORT_CAST,
        faction = "Neutral",
        label = "Teleport to Moonglade",
        spell = "Teleport: Moonglade",
      })
    end
  end
  local _ = startNode
  local _ = nodes
end

local function buildAdjacency(query, startNode, goalNode, allowDiscover)
  local faction = query.faction
  local speed = Layover.Movement.speedYdsPerSec(query)
  local known = collectKnown(query)
  local nodes = Layover.Util.shallowCopy(Layover.Graph.getNodes())
  nodes[START_ID] = cloneNode(startNode, START_ID)
  nodes[GOAL_ID] = cloneNode(goalNode, GOAL_ID)

  local adj = {}
  for id in pairs(nodes) do
    adj[id] = {}
  end

  local staticEdges = Layover.Graph.getEdges()
  for i = 1, #staticEdges do
    local e = staticEdges[i]
    if nodes[e.from] and nodes[e.to] then
      if e.mode == "flight" then
        if flightAllowed(e, known, allowDiscover, faction) then
          local copy = Layover.Util.shallowCopy(e)
          if allowDiscover and not known[e.to] then
            copy.discover = true
          end
          addAdj(adj, copy)
        end
      elseif edgeUsable(e, faction) then
        addAdj(adj, e)
      end
    end
  end

  -- Ground travel between any two nodes on the same landmass.
  local ids = {}
  for id, node in pairs(nodes) do
    if id ~= START_ID and id ~= GOAL_ID then
      ids[#ids + 1] = id
    end
  end
  -- Ground travel is not faction-gated: players can walk into enemy cities.
  -- Flights, zeppelins, and the tram stay faction-filtered above.
  for i = 1, #ids do
    local aId = ids[i]
    local a = nodes[aId]
    local eStart = groundEdge(START_ID, aId, startNode, a, speed)
    if eStart and Layover.Movement.sameLandmass(startNode, a) then
      addAdj(adj, eStart)
    end
    local eGoal = groundEdge(aId, GOAL_ID, a, goalNode, speed)
    if eGoal and Layover.Movement.sameLandmass(a, goalNode) then
      addAdj(adj, eGoal)
    end
  end
  if Layover.Movement.sameLandmass(startNode, goalNode) then
    local direct = groundEdge(START_ID, GOAL_ID, startNode, goalNode, speed)
    if direct then
      addAdj(adj, direct)
    end
  end

  -- Also allow walking between hubs (needed so a discovery walk can insert
  -- an intermediate FP between two legs).
  for i = 1, #ids do
    local a = nodes[ids[i]]
    for j = i + 1, #ids do
      local b = nodes[ids[j]]
      if Layover.Movement.sameLandmass(a, b) then
        local ab = groundEdge(a.id, b.id, a, b, speed)
        local ba = groundEdge(b.id, a.id, b, a, speed)
        if ab then
          addAdj(adj, ab)
        end
        if ba then
          addAdj(adj, ba)
        end
      end
    end
  end

  addAbilityEdges(adj, nodes, query, startNode)
  return adj, nodes, known, speed
end

local function dijkstra(adj, nodes)
  local dist = {}
  local prev = {}
  for id in pairs(nodes) do
    dist[id] = math.huge
  end
  dist[START_ID] = 0
  local heap = Layover.Util.heapNew()
  Layover.Util.heapPush(heap, 0, START_ID)

  while not Layover.Util.heapEmpty(heap) do
    local d, u = Layover.Util.heapPop(heap)
    if u == GOAL_ID then
      break
    end
    if d <= dist[u] then
      local edges = adj[u]
      if edges then
        for i = 1, #edges do
          local e = edges[i]
          local nd = d + e.seconds
          if nd < dist[e.to] then
            dist[e.to] = nd
            prev[e.to] = { from = u, edge = e }
            Layover.Util.heapPush(heap, nd, e.to)
          end
        end
      end
    end
  end
  return dist, prev
end

local function reconstruct(prev, nodes)
  if not prev[GOAL_ID] then
    return nil
  end
  local hops = {}
  local cur = GOAL_ID
  while cur ~= START_ID do
    local step = prev[cur]
    if not step then
      return nil
    end
    hops[#hops + 1] = step.edge
    cur = step.from
  end
  local path = {}
  for i = #hops, 1, -1 do
    path[#path + 1] = hops[i]
  end
  local _ = nodes
  return path
end

local MODE_LABEL = {
  ground = "Travel",
  flight = "Fly",
  boat = "Take the boat",
  zeppelin = "Take the zeppelin",
  tram = "Take the Deeprun Tram",
  portal = "Take the portal",
  hearth = "Hearthstone",
  astral_recall = "Astral Recall",
  teleport = "Teleport",
}

local function nodeName(nodes, id, fallback)
  if id == START_ID then
    return "your location"
  end
  if id == GOAL_ID then
    return (fallback and fallback.name) or "your destination"
  end
  local n = nodes[id]
  return n and n.name or id
end

local function compressPath(path, nodes, goalNode, speed)
  local steps = {}
  local i = 1
  while i <= #path do
    local edge = path[i]
    if edge.mode == "ground" then
      local j = i
      while j + 1 <= #path and path[j + 1].mode == "ground" do
        j = j + 1
      end
      local last = path[j]
      local seconds = 0
      for k = i, j do
        seconds = seconds + path[k].seconds
      end
      local destId = last.to
      local verb = Layover.Movement.travelVerb(speed)
      local label = verb .. " to " .. nodeName(nodes, destId, goalNode)
      steps[#steps + 1] = {
        mode = "ground",
        fromId = path[i].from,
        toId = destId,
        seconds = seconds,
        label = label,
        discover = false,
      }
      i = j + 1
    else
      local destName = nodeName(nodes, edge.to, goalNode)
      local label = edge.label
      if not label then
        local prefix = MODE_LABEL[edge.mode] or edge.mode
        if edge.mode == "flight" then
          label = "Fly to " .. destName
          if edge.discover then
            label = label .. " (discover FP)"
          end
        elseif edge.mode == "tram" then
          label = "Take the Deeprun Tram to " .. destName
        elseif edge.mode == "portal" then
          label = "Take the portal to " .. destName
        elseif edge.mode == "boat" then
          label = "Take the boat to " .. destName
        elseif edge.mode == "zeppelin" then
          label = "Take the zeppelin to " .. destName
        else
          label = prefix .. " to " .. destName
        end
      end
      steps[#steps + 1] = {
        mode = edge.mode,
        fromId = edge.from,
        toId = edge.to,
        seconds = edge.seconds,
        label = label,
        discover = edge.discover and true or false,
        spell = edge.spell,
        faction = edge.faction,
      }
      i = i + 1
    end
  end

  for s = 1, #steps do
    local step = steps[s]
    local toNode = nodes[step.toId]
    if toNode then
      step.to = {
        id = toNode.id,
        name = toNode.name,
        uiMapID = toNode.uiMapID,
        zx = toNode.zx,
        zy = toNode.zy,
        wx = toNode.wx,
        wy = toNode.wy,
        continent = toNode.continent,
        kind = toNode.kind,
      }
    end
    local fromNode = nodes[step.fromId]
    if fromNode then
      step.from = {
        id = fromNode.id,
        name = fromNode.name,
        uiMapID = fromNode.uiMapID,
      }
    end
    step.index = s
    step.done = false
  end
  return steps
end

local function pathNodeIds(path)
  local ids = { START_ID }
  for i = 1, #path do
    ids[#ids + 1] = path[i].to
  end
  return ids
end

local function usesUnknownFlight(path, known)
  local found = {}
  for i = 1, #path do
    local e = path[i]
    if e.mode == "flight" and e.discover then
      found[#found + 1] = e.to
    end
  end
  return found
end

local function runOnce(query, startNode, goalNode, allowDiscover)
  local adj, nodes, known, speed = buildAdjacency(query, startNode, goalNode, allowDiscover)
  local dist, prev = dijkstra(adj, nodes)
  local path = reconstruct(prev, nodes)
  if not path then
    return {
      ok = false,
      totalSeconds = math.huge,
      steps = {},
      path = {},
      pathNodeIds = {},
      known = known,
      speed = speed,
    }
  end
  local steps = compressPath(path, nodes, goalNode, speed)
  local total = dist[GOAL_ID]
  return {
    ok = true,
    totalSeconds = total,
    steps = steps,
    path = path,
    pathNodeIds = pathNodeIds(path),
    known = known,
    speed = speed,
    nodes = nodes,
    discoverFlights = usesUnknownFlight(path, known),
  }
end

function Router.route(query)
  ensure()
  query = query or {}
  local faction = query.faction
  local startNode = resolveEndpoint(query.from, faction, START_ID)
  local goalNode = resolveEndpoint(query.to, faction, GOAL_ID)
  if not startNode then
    return { ok = false, error = "unknown_start" }
  end
  if not goalNode then
    return { ok = false, error = "unknown_destination", query = query.to }
  end

  local already = Layover.Movement.nodeDistance(startNode, goalNode)
  if Layover.Movement.sameLandmass(startNode, goalNode) and already < 80 then
    return {
      ok = true,
      totalSeconds = 0,
      steps = {},
      path = {},
      pathNodeIds = { START_ID, GOAL_ID },
      from = startNode,
      to = goalNode,
      faction = faction,
      eta = "0s",
      alreadyThere = true,
    }
  end

  local primary = runOnce(query, startNode, goalNode, false)
  local discover = runOnce(query, startNode, goalNode, true)

  primary.from = startNode
  primary.to = goalNode
  primary.faction = faction
  primary.eta = Layover.Util.formatDuration(primary.totalSeconds or 0)

  if discover.ok and primary.ok then
    local saved = primary.totalSeconds - discover.totalSeconds
    if saved >= 30 and #discover.discoverFlights > 0 then
      local names = {}
      for i = 1, #discover.discoverFlights do
        local id = discover.discoverFlights[i]
        local n = Layover.Graph.getNode(id) or (discover.nodes and discover.nodes[id])
        names[#names + 1] = n and n.name or id
      end
      primary.suggestion = {
        savedSeconds = saved,
        savedEta = Layover.Util.formatDuration(saved),
        flightIds = discover.discoverFlights,
        names = names,
        text = "Grab " .. table.concat(names, ", ") .. " along the way (" .. Layover.Util.formatDuration(saved) .. " faster)",
      }
      primary.discoverRoute = discover
    end
  end

  if query.preferDiscover and discover.ok then
    discover.from = startNode
    discover.to = goalNode
    discover.faction = faction
    discover.eta = Layover.Util.formatDuration(discover.totalSeconds or 0)
    discover.suggestion = primary.suggestion
    return discover
  end

  return primary
end

function Router.pathContainsMode(result, mode)
  if not result or not result.steps then
    return false
  end
  for i = 1, #result.steps do
    if result.steps[i].mode == mode then
      return true
    end
  end
  return false
end

function Router.pathContainsNode(result, nodeId)
  if not result then
    return false
  end
  local ids = result.pathNodeIds or {}
  for i = 1, #ids do
    if ids[i] == nodeId then
      return true
    end
  end
  local steps = result.steps or {}
  for i = 1, #steps do
    if steps[i].toId == nodeId or steps[i].fromId == nodeId then
      return true
    end
  end
  return false
end

function Router.pathFactions(result)
  local set = {}
  if not result or not result.path then
    return set
  end
  for i = 1, #result.path do
    local f = result.path[i].faction
    if f and f ~= "Neutral" then
      set[f] = true
    end
  end
  return set
end

function Router.describe(result)
  if not result or not result.ok then
    return "No route found."
  end
  local lines = {}
  lines[#lines + 1] = "Total ETA: " .. (result.eta or Layover.Util.formatDuration(result.totalSeconds))
  for i = 1, #result.steps do
    local s = result.steps[i]
    local mark = s.done and "[x]" or "[ ]"
    lines[#lines + 1] = string.format("%s %d. %s  (~%s)", mark, i, s.label, Layover.Util.formatDuration(s.seconds))
  end
  if result.suggestion then
    lines[#lines + 1] = "Tip: " .. result.suggestion.text
  end
  return table.concat(lines, "\n")
end
