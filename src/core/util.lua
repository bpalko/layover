Layover = Layover or {}
local Util = {}
Layover.Util = Util

function Util.clamp(value, lo, hi)
  if value < lo then
    return lo
  end
  if value > hi then
    return hi
  end
  return value
end

function Util.round(value)
  if value >= 0 then
    return math.floor(value + 0.5)
  end
  return math.ceil(value - 0.5)
end

function Util.dist(ax, ay, bx, by)
  local dx = ax - bx
  local dy = ay - by
  return math.sqrt(dx * dx + dy * dy)
end

function Util.startsWith(str, prefix)
  return string.sub(str, 1, #prefix) == prefix
end

function Util.trim(str)
  return (str:gsub("^%s+", ""):gsub("%s+$", ""))
end

function Util.normalize(str)
  if not str then
    return ""
  end
  str = str:lower()
  str = str:gsub("'", "")
  str = str:gsub("[^%w%s]", " ")
  str = str:gsub("%s+", " ")
  return Util.trim(str)
end

function Util.splitWords(str)
  local words = {}
  for word in str:gmatch("%S+") do
    words[#words + 1] = word
  end
  return words
end

function Util.contains(haystack, needle)
  return string.find(haystack, needle, 1, true) ~= nil
end

function Util.shallowCopy(tbl)
  local copy = {}
  for k, v in pairs(tbl) do
    copy[k] = v
  end
  return copy
end

function Util.keys(tbl)
  local list = {}
  for k in pairs(tbl) do
    list[#list + 1] = k
  end
  return list
end

function Util.count(tbl)
  local n = 0
  for _ in pairs(tbl) do
    n = n + 1
  end
  return n
end

function Util.formatDuration(seconds)
  seconds = math.max(0, Util.round(seconds or 0))
  if seconds < 60 then
    return seconds .. "s"
  end
  local minutes = math.floor(seconds / 60)
  local rem = seconds % 60
  if minutes < 60 then
    if rem == 0 then
      return minutes .. "m"
    end
    return minutes .. "m " .. rem .. "s"
  end
  local hours = math.floor(minutes / 60)
  minutes = minutes % 60
  if minutes == 0 then
    return hours .. "h"
  end
  return hours .. "h " .. minutes .. "m"
end

function Util.levenshtein(a, b)
  if a == b then
    return 0
  end
  local la, lb = #a, #b
  if la == 0 then
    return lb
  end
  if lb == 0 then
    return la
  end
  if math.abs(la - lb) > 4 and math.min(la, lb) > 4 then
    return 99
  end
  local prev = {}
  local curr = {}
  for j = 0, lb do
    prev[j] = j
  end
  for i = 1, la do
    curr[0] = i
    local ca = a:sub(i, i)
    for j = 1, lb do
      local cost = (ca == b:sub(j, j)) and 0 or 1
      local del = prev[j] + 1
      local ins = curr[j - 1] + 1
      local sub = prev[j - 1] + cost
      local best = del
      if ins < best then
        best = ins
      end
      if sub < best then
        best = sub
      end
      curr[j] = best
    end
    prev, curr = curr, prev
  end
  return prev[lb]
end

-- Binary min-heap. Items are { key = number, value = any }.
function Util.heapNew()
  return { n = 0 }
end

function Util.heapPush(heap, key, value)
  local i = heap.n + 1
  heap.n = i
  heap[i] = { key = key, value = value }
  while i > 1 do
    local parent = math.floor(i / 2)
    if heap[parent].key <= heap[i].key then
      break
    end
    heap[parent], heap[i] = heap[i], heap[parent]
    i = parent
  end
end

function Util.heapPop(heap)
  if heap.n == 0 then
    return nil
  end
  local root = heap[1]
  local last = heap[heap.n]
  heap[heap.n] = nil
  heap.n = heap.n - 1
  if heap.n == 0 then
    return root.key, root.value
  end
  heap[1] = last
  local i = 1
  while true do
    local left = i * 2
    local right = left + 1
    local smallest = i
    if left <= heap.n and heap[left].key < heap[smallest].key then
      smallest = left
    end
    if right <= heap.n and heap[right].key < heap[smallest].key then
      smallest = right
    end
    if smallest == i then
      break
    end
    heap[i], heap[smallest] = heap[smallest], heap[i]
    i = smallest
  end
  return root.key, root.value
end

function Util.heapEmpty(heap)
  return heap.n == 0
end
