Layover = Layover or {}
local Steps = {}
Layover.Steps = Steps

function Steps.new(route)
  if not route or not route.ok then
    return {
      ok = false,
      steps = {},
      currentIndex = 0,
      complete = true,
      totalSeconds = 0,
      remainingSeconds = 0,
    }
  end
  local steps = {}
  for i = 1, #route.steps do
    local s = route.steps[i]
    steps[i] = {
      index = i,
      mode = s.mode,
      fromId = s.fromId,
      toId = s.toId,
      from = s.from,
      to = s.to,
      seconds = s.seconds,
      label = s.label,
      discover = s.discover,
      spell = s.spell,
      done = false,
    }
  end
  return {
    ok = true,
    steps = steps,
    currentIndex = (#steps > 0) and 1 or 0,
    complete = #steps == 0,
    totalSeconds = route.totalSeconds,
    remainingSeconds = route.totalSeconds,
    from = route.from,
    to = route.to,
    suggestion = route.suggestion,
    eta = route.eta,
    faction = route.faction,
  }
end

local function remaining(state)
  local sum = 0
  for i = 1, #state.steps do
    if not state.steps[i].done then
      sum = sum + (state.steps[i].seconds or 0)
    end
  end
  return sum
end

local function snapshotWorld(snapshot)
  if snapshot.wx and snapshot.wy then
    return snapshot.wx, snapshot.wy, snapshot.continent
  end
  if snapshot.uiMapID then
    return Layover.Graph.mapToWorld(
      snapshot.uiMapID,
      snapshot.zx or snapshot.x or 0.5,
      snapshot.zy or snapshot.y or 0.5
    )
  end
  return nil, nil, snapshot.continent
end

local function nearTarget(snapshot, target, radiusYards)
  if not target then
    return false
  end
  radiusYards = radiusYards or 120
  local wx, wy = snapshotWorld(snapshot)
  if wx and target.wx then
    if Layover.Util.dist(wx, wy, target.wx, target.wy) <= radiusYards then
      return true
    end
  end
  if snapshot.uiMapID and target.uiMapID and snapshot.uiMapID == target.uiMapID then
    local zx = snapshot.zx or snapshot.x
    local zy = snapshot.zy or snapshot.y
    if zx and zy and target.zx and target.zy then
      local dx = zx - target.zx
      local dy = zy - target.zy
      -- ~0.04 of a zone is typically a few hundred yards.
      if math.sqrt(dx * dx + dy * dy) <= 0.05 then
        return true
      end
    end
  end
  return false
end

local function inZone(snapshot, target)
  if not snapshot or not target then
    return false
  end
  if snapshot.uiMapID and target.uiMapID and snapshot.uiMapID == target.uiMapID then
    return true
  end
  if snapshot.zoneName and target.name then
    local a = Layover.Util.normalize(snapshot.zoneName)
    local b = Layover.Util.normalize(target.name)
    if a ~= "" and (a == b or Layover.Util.contains(a, b) or Layover.Util.contains(b, a)) then
      return true
    end
  end
  return false
end

function Steps.isComplete(step, snapshot)
  if not step or step.done then
    return true
  end
  snapshot = snapshot or {}
  local target = step.to
  local mode = step.mode

  if snapshot.completedStepIndex == step.index then
    return true
  end
  if snapshot.atNode and (snapshot.atNode == step.toId or (target and snapshot.atNode == target.id)) then
    return true
  end

  if mode == "flight" then
    if snapshot.onTaxi then
      return false
    end
    local taxiDest = snapshot.taxiEndedAt
    if taxiDest and target and (taxiDest == step.toId or taxiDest == target.name) then
      return true
    end
    local kind = target and target.kind
    local atHub = kind == "flight" or kind == "town" or kind == "city"
    return nearTarget(snapshot, target, 160) or (inZone(snapshot, target) and atHub)
  end

  if mode == "boat" or mode == "zeppelin" then
    if snapshot.onTransport and snapshot.transportDest == step.toId then
      return true
    end
    return nearTarget(snapshot, target, 200) or inZone(snapshot, target)
  end

  if mode == "tram" or mode == "portal" then
    return nearTarget(snapshot, target, 180) or inZone(snapshot, target)
  end

  if mode == "hearth" or mode == "astral_recall" or mode == "teleport" then
    return nearTarget(snapshot, target, 220) or inZone(snapshot, target)
  end

  -- Ground / default: proximity, or arrival in the destination zone for
  -- the final step when the target is a zone/city/dungeon.
  if step.toId == "__goal" then
    return nearTarget(snapshot, target, 80) or inZone(snapshot, target)
  end
  return nearTarget(snapshot, target, 120)
end

local function syncIndex(state)
  local firstOpen = 0
  for i = 1, #state.steps do
    if not state.steps[i].done then
      firstOpen = i
      break
    end
  end
  if firstOpen == 0 then
    state.currentIndex = #state.steps + 1
    state.complete = true
  else
    state.currentIndex = firstOpen
    state.complete = false
  end
  state.remainingSeconds = remaining(state)
  state.remainingEta = Layover.Util.formatDuration(state.remainingSeconds)
end

function Steps.advance(state, snapshot)
  if not state or not state.ok or state.complete then
    return state
  end
  -- Advance through every consecutive completed step so a large zone
  -- change (e.g. after a boat) can clear boarding + arrival together.
  local guard = 0
  while not state.complete and guard < #state.steps + 2 do
    guard = guard + 1
    local step = state.steps[state.currentIndex]
    if not step then
      break
    end
    if Steps.isComplete(step, snapshot) then
      step.done = true
      syncIndex(state)
    else
      break
    end
  end
  return state
end

function Steps.skip(state)
  if not state or not state.ok or state.complete then
    return state
  end
  local step = state.steps[state.currentIndex]
  if step then
    step.done = true
    step.skipped = true
  end
  syncIndex(state)
  return state
end

function Steps.clear(state)
  if not state then
    return { ok = false, steps = {}, currentIndex = 0, complete = true }
  end
  for i = 1, #state.steps do
    state.steps[i].done = true
    state.steps[i].skipped = true
  end
  syncIndex(state)
  return state
end

function Steps.current(state)
  if not state or not state.ok or state.complete then
    return nil
  end
  return state.steps[state.currentIndex]
end

function Steps.checklist(state)
  local rows = {}
  if not state then
    return rows
  end
  for i = 1, #state.steps do
    local s = state.steps[i]
    local status = "pending"
    if s.done then
      status = s.skipped and "skipped" or "done"
    elseif i == state.currentIndex then
      status = "current"
    end
    rows[#rows + 1] = {
      index = i,
      label = s.label,
      eta = Layover.Util.formatDuration(s.seconds),
      seconds = s.seconds,
      mode = s.mode,
      status = status,
      discover = s.discover,
    }
  end
  return rows
end

function Steps.simulate(state, snapshots)
  snapshots = snapshots or {}
  for i = 1, #snapshots do
    Steps.advance(state, snapshots[i])
    if state.complete then
      break
    end
  end
  return state
end
