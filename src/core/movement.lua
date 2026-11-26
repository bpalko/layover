Layover = Layover or {}
local Movement = {}
Layover.Movement = Movement

-- Classic Era base run speed is 7 yards/second.
Movement.BASE_RUN_YDS = 7
Movement.WALK_YDS = 2.5
Movement.MOUNT_60 = 1.6
Movement.MOUNT_100 = 2.0
Movement.TRAVEL_FORM = 1.4 -- Druid Travel Form / Shaman Ghost Wolf (Vanilla)
Movement.CHEETAH = 1.3 -- Hunter Aspect of the Cheetah
Movement.PATHING_SAME_ZONE = 1.15
Movement.PATHING_CROSS_ZONE = 1.40
Movement.MIN_GROUND_SECONDS = 8
Movement.HEARTH_CAST = 10
Movement.TELEPORT_CAST = 10

function Movement.speedYdsPerSec(profile)
  profile = profile or {}
  if profile.speedYdsPerSec then
    return profile.speedYdsPerSec
  end
  local base = Movement.BASE_RUN_YDS
  local best = 1.0
  if profile.mounted100 or profile.mount == "100" then
    best = math.max(best, Movement.MOUNT_100)
  end
  if profile.mounted60 or profile.mount == "60" then
    best = math.max(best, Movement.MOUNT_60)
  end
  if profile.mount == "100" or profile.mount == "60" then
    return base * best
  end
  local class = profile.class
  if class == "DRUID" and (profile.travelForm or profile.level and profile.level >= 30) then
    best = math.max(best, Movement.TRAVEL_FORM)
  end
  if class == "SHAMAN" and (profile.ghostWolf or profile.level and profile.level >= 20) then
    best = math.max(best, Movement.TRAVEL_FORM)
  end
  if class == "HUNTER" and (profile.cheetah or profile.level and profile.level >= 20) then
    best = math.max(best, Movement.CHEETAH)
  end
  if profile.mounted100 then
    best = math.max(best, Movement.MOUNT_100)
  elseif profile.mounted60 then
    best = math.max(best, Movement.MOUNT_60)
  end
  return base * best
end

function Movement.pathingMultiplier(fromNode, toNode)
  if fromNode and toNode and fromNode.uiMapID and fromNode.uiMapID == toNode.uiMapID then
    return Movement.PATHING_SAME_ZONE
  end
  return Movement.PATHING_CROSS_ZONE
end

function Movement.groundSeconds(distanceYards, speedYdsPerSec, pathing)
  speedYdsPerSec = speedYdsPerSec or Movement.BASE_RUN_YDS
  pathing = pathing or Movement.PATHING_CROSS_ZONE
  if speedYdsPerSec <= 0 then
    speedYdsPerSec = Movement.BASE_RUN_YDS
  end
  local seconds = (distanceYards * pathing) / speedYdsPerSec
  if seconds < Movement.MIN_GROUND_SECONDS then
    return Movement.MIN_GROUND_SECONDS
  end
  return seconds
end

function Movement.nodeDistance(a, b)
  if not a or not b or not a.wx or not b.wx then
    return math.huge
  end
  return Layover.Util.dist(a.wx, a.wy, b.wx, b.wy)
end

function Movement.travelVerb(speedYdsPerSec)
  if (speedYdsPerSec or 0) > Movement.BASE_RUN_YDS + 0.1 then
    return "Ride"
  end
  return "Walk"
end

function Movement.sameLandmass(a, b)
  if not a or not b then
    return false
  end
  return a.continent == b.continent
end
