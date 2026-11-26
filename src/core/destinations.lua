Layover = Layover or {}
local Destinations = {}
Layover.Destinations = Destinations

local function graphReady()
  if not Layover.Graph._built then
    Layover.Graph.build()
  end
end

function Destinations.resolveBind(bindLocation)
  graphReady()
  if not bindLocation or bindLocation == "" then
    return nil
  end
  local key = Layover.Util.normalize(bindLocation)
  local bindMap = Layover.Data.bindNamesNormalized
  if not bindMap then
    bindMap = {}
    for raw, nodeId in pairs(Layover.Data.bindNames) do
      bindMap[Layover.Util.normalize(raw)] = nodeId
    end
    Layover.Data.bindNamesNormalized = bindMap
  end
  local id = bindMap[key] or Layover.Data.nodesByAlias[key]
  if id then
    return Layover.Graph.getNode(id)
  end
  -- Fuzzy against node names (inn names often include the town).
  local best, bestScore = nil, 0
  for nodeId, node in pairs(Layover.Graph.getNodes()) do
    local nkey = Layover.Util.normalize(node.name)
    if nkey == key or Layover.Util.contains(key, nkey) or Layover.Util.contains(nkey, key) then
      return node
    end
    local score = 0
    local dist = Layover.Util.levenshtein(key, nkey)
    if dist <= 2 and #key >= 4 then
      score = 50 - dist
    end
    if score > bestScore then
      bestScore = score
      best = node
    end
    local _ = nodeId
  end
  if bestScore >= 48 then
    return best
  end
  return nil
end

local function factionOverride(normalized, faction)
  local entry = Layover.Data.factionDestinations[normalized]
  if entry then
    local id = entry[faction] or entry.Alliance or entry.Horde
    return id and Layover.Graph.getNode(id) or nil
  end
  return nil
end

local function scoreCandidate(query, node)
  local q = query
  local name = Layover.Util.normalize(node.name)
  local id = Layover.Util.normalize(node.id)
  if q == id or q == name then
    return 100
  end
  for i = 1, #(node.aliases or {}) do
    if Layover.Util.normalize(node.aliases[i]) == q then
      return 98
    end
  end
  if node.taxiName and Layover.Util.normalize(node.taxiName) == q then
    return 95
  end
  if Layover.Util.startsWith(name, q) or Layover.Util.startsWith(id, q) then
    return 80 - math.min(10, #name - #q)
  end
  if Layover.Util.contains(name, q) or Layover.Util.contains(id, q) then
    return 60
  end
  local words = Layover.Util.splitWords(q)
  if #words > 1 then
    local all = true
    for i = 1, #words do
      if not (Layover.Util.contains(name, words[i]) or Layover.Util.contains(id, words[i])) then
        all = false
        break
      end
    end
    if all then
      return 55
    end
  end
  local dist = Layover.Util.levenshtein(q, name)
  if #q >= 3 and dist <= 2 then
    return 40 - dist
  end
  dist = Layover.Util.levenshtein(q, id)
  if #q >= 3 and dist <= 2 then
    return 38 - dist
  end
  return 0
end

function Destinations.resolve(query, faction)
  graphReady()
  if type(query) == "table" then
    if query.nodeId then
      return Layover.Graph.getNode(query.nodeId), 100
    end
    if query.uiMapID then
      local node = Layover.Graph.makeCoordNode(
        "waypoint",
        query.uiMapID,
        query.zx or query.x or 0.5,
        query.zy or query.y or 0.5,
        query.name or "Map pin"
      )
      return node, 100
    end
    query = query.name or query.query
  end
  if not query or query == "" then
    return nil, 0
  end
  local q = Layover.Util.normalize(query)
  if q == "" then
    return nil, 0
  end

  local override = factionOverride(q, faction)
  if override then
    return override, 100
  end

  local zoneId = Layover.Data.zoneAliases[q]
  if zoneId then
    return Layover.Graph.getNode(zoneId), 90
  end

  local aliasId = Layover.Data.nodesByAlias[q]
  if aliasId then
    return Layover.Graph.getNode(aliasId), 98
  end

  local best, bestScore = nil, 0
  for _, node in pairs(Layover.Graph.getNodes()) do
    local score = scoreCandidate(q, node)
    if score > bestScore then
      bestScore = score
      best = node
    end
  end
  if bestScore >= 38 then
    return best, bestScore
  end
  return nil, 0
end

function Destinations.search(query, faction, limit)
  graphReady()
  limit = limit or 8
  local q = Layover.Util.normalize(query or "")
  local results = {}
  if q == "" then
    -- Popular destinations when the box is empty.
    local popular = {
      "stormwind", "ironforge", "darnassus", "orgrimmar", "undercity",
      "thunder_bluff", "sm", "deadmines", "brd", "strat", "scholo", "rfc",
    }
    for i = 1, #popular do
      local node = Destinations.resolve(popular[i], faction)
      if node then
        results[#results + 1] = { node = node, score = 70, label = node.name }
      end
    end
    return results
  end

  local override = factionOverride(q, faction)
  if override then
    results[#results + 1] = { node = override, score = 100, label = override.name }
  end

  local seen = {}
  for i = 1, #results do
    seen[results[i].node.id] = true
  end

  for _, node in pairs(Layover.Graph.getNodes()) do
    if not seen[node.id] then
      local score = scoreCandidate(q, node)
      if score > 0 then
        results[#results + 1] = { node = node, score = score, label = node.name }
        seen[node.id] = true
      end
    end
  end

  table.sort(results, function(a, b)
    if a.score == b.score then
      return a.label < b.label
    end
    return a.score > b.score
  end)

  local trimmed = {}
  for i = 1, math.min(limit, #results) do
    trimmed[i] = results[i]
  end
  return trimmed
end

function Destinations.listCanonical()
  graphReady()
  local list = {}
  for id, node in pairs(Layover.Graph.getNodes()) do
    if node.kind ~= "tram" and node.kind ~= "port" then
      list[#list + 1] = {
        id = id,
        name = node.name,
        kind = node.kind,
        faction = node.faction,
        aliases = node.aliases,
      }
    end
  end
  table.sort(list, function(a, b)
    return a.name < b.name
  end)
  return list
end
