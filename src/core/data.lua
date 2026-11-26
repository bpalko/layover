Layover = Layover or {}
local Data = {}
Layover.Data = Data

-- Geographic model: wx increases east, wy increases north, units are yards.
-- Zone map coords: (0,0) is the north-west / top-left of the zone map.
-- wx = wx0 + zx * w
-- wy = wy0 + (1 - zy) * h

local zones = {
  -- Eastern Kingdoms
  [1415] = { name = "Eastern Kingdoms", continent = "EK", wx0 = 0, wy0 = 0, w = 25000, h = 28000 },
  [1429] = { name = "Elwynn Forest", continent = "EK", wx0 = 14800, wy0 = 8200, w = 3200, h = 2600 },
  [1453] = { name = "Stormwind City", continent = "EK", wx0 = 14100, wy0 = 8800, w = 1400, h = 1400 },
  [1436] = { name = "Westfall", continent = "EK", wx0 = 12000, wy0 = 6400, w = 2800, h = 2800 },
  [1431] = { name = "Duskwood", continent = "EK", wx0 = 14800, wy0 = 6200, w = 3700, h = 2300 },
  [1433] = { name = "Redridge Mountains", continent = "EK", wx0 = 18000, wy0 = 8200, w = 3000, h = 2600 },
  [1430] = { name = "Deadwind Pass", continent = "EK", wx0 = 18500, wy0 = 7000, w = 1600, h = 1500 },
  [1434] = { name = "Stranglethorn Vale", continent = "EK", wx0 = 14000, wy0 = 400, w = 4500, h = 6000 },
  [1435] = { name = "Swamp of Sorrows", continent = "EK", wx0 = 20000, wy0 = 7000, w = 3000, h = 2500 },
  [1419] = { name = "Blasted Lands", continent = "EK", wx0 = 19500, wy0 = 4500, w = 3000, h = 2500 },
  [1428] = { name = "Burning Steppes", continent = "EK", wx0 = 17500, wy0 = 10800, w = 3500, h = 2000 },
  [1427] = { name = "Searing Gorge", continent = "EK", wx0 = 15500, wy0 = 11800, w = 2800, h = 2000 },
  [1418] = { name = "Badlands", continent = "EK", wx0 = 18500, wy0 = 12800, w = 3500, h = 2200 },
  [1426] = { name = "Dun Morogh", continent = "EK", wx0 = 12500, wy0 = 14000, w = 3500, h = 3000 },
  [1455] = { name = "Ironforge", continent = "EK", wx0 = 14200, wy0 = 15200, w = 1200, h = 1300 },
  [1432] = { name = "Loch Modan", continent = "EK", wx0 = 16000, wy0 = 14000, w = 3000, h = 2800 },
  [1437] = { name = "Wetlands", continent = "EK", wx0 = 15500, wy0 = 16800, w = 3500, h = 2700 },
  [1417] = { name = "Arathi Highlands", continent = "EK", wx0 = 18500, wy0 = 18800, w = 4000, h = 2700 },
  [1424] = { name = "Hillsbrad Foothills", continent = "EK", wx0 = 15000, wy0 = 19500, w = 3500, h = 2500 },
  [1416] = { name = "Alterac Mountains", continent = "EK", wx0 = 15500, wy0 = 21500, w = 2500, h = 1700 },
  [1421] = { name = "Silverpine Forest", continent = "EK", wx0 = 12500, wy0 = 20000, w = 2700, h = 3500 },
  [1425] = { name = "The Hinterlands", continent = "EK", wx0 = 19500, wy0 = 21000, w = 4000, h = 2500 },
  [1422] = { name = "Western Plaguelands", continent = "EK", wx0 = 15500, wy0 = 22000, w = 4000, h = 2500 },
  [1420] = { name = "Tirisfal Glades", continent = "EK", wx0 = 12500, wy0 = 23200, w = 5000, h = 3300 },
  [1458] = { name = "Undercity", continent = "EK", wx0 = 13600, wy0 = 24300, w = 1200, h = 1200 },
  [1423] = { name = "Eastern Plaguelands", continent = "EK", wx0 = 19500, wy0 = 23200, w = 4500, h = 3300 },
  -- Kalimdor mainland
  [1414] = { name = "Kalimdor", continent = "Kalimdor", wx0 = 0, wy0 = 0, w = 22000, h = 30000 },
  [1439] = { name = "Darkshore", continent = "Kalimdor", wx0 = 7000, wy0 = 22000, w = 4000, h = 4000 },
  [1440] = { name = "Ashenvale", continent = "Kalimdor", wx0 = 8000, wy0 = 18500, w = 6000, h = 3500 },
  [1447] = { name = "Azshara", continent = "Kalimdor", wx0 = 14000, wy0 = 19000, w = 4500, h = 3500 },
  [1448] = { name = "Felwood", continent = "Kalimdor", wx0 = 9000, wy0 = 21500, w = 3500, h = 3000 },
  [1450] = { name = "Moonglade", continent = "Kalimdor", wx0 = 11500, wy0 = 23800, w = 2500, h = 2000 },
  [1452] = { name = "Winterspring", continent = "Kalimdor", wx0 = 13500, wy0 = 23000, w = 3500, h = 3000 },
  [1442] = { name = "Stonetalon Mountains", continent = "Kalimdor", wx0 = 6500, wy0 = 16500, w = 3500, h = 3000 },
  [1411] = { name = "Durotar", continent = "Kalimdor", wx0 = 15000, wy0 = 15500, w = 3000, h = 3500 },
  [1454] = { name = "Orgrimmar", continent = "Kalimdor", wx0 = 16000, wy0 = 17500, w = 1500, h = 1600 },
  [1413] = { name = "The Barrens", continent = "Kalimdor", wx0 = 11500, wy0 = 11500, w = 4500, h = 5500 },
  [1412] = { name = "Mulgore", continent = "Kalimdor", wx0 = 8500, wy0 = 14000, w = 3000, h = 3500 },
  [1456] = { name = "Thunder Bluff", continent = "Kalimdor", wx0 = 9200, wy0 = 15500, w = 1300, h = 1300 },
  [1443] = { name = "Desolace", continent = "Kalimdor", wx0 = 5500, wy0 = 13000, w = 3500, h = 3500 },
  [1445] = { name = "Dustwallow Marsh", continent = "Kalimdor", wx0 = 14500, wy0 = 10000, w = 4000, h = 3500 },
  [1444] = { name = "Feralas", continent = "Kalimdor", wx0 = 5000, wy0 = 9000, w = 5000, h = 3500 },
  [1441] = { name = "Thousand Needles", continent = "Kalimdor", wx0 = 10500, wy0 = 8500, w = 4000, h = 3000 },
  [1446] = { name = "Tanaris", continent = "Kalimdor", wx0 = 12000, wy0 = 5000, w = 4500, h = 3500 },
  [1449] = { name = "Un'Goro Crater", continent = "Kalimdor", wx0 = 10000, wy0 = 3500, w = 3500, h = 2500 },
  [1451] = { name = "Silithus", continent = "Kalimdor", wx0 = 7000, wy0 = 3000, w = 3500, h = 2500 },
  -- Teldrassil is an island; ground travel cannot reach Kalimdor mainland.
  [1438] = { name = "Teldrassil", continent = "Teldrassil", wx0 = 0, wy0 = 0, w = 5000, h = 5000 },
  [1457] = { name = "Darnassus", continent = "Teldrassil", wx0 = 1500, wy0 = 2800, w = 1800, h = 1800 },
}

Data.zones = zones

local function worldOf(uiMapID, zx, zy)
  local z = zones[uiMapID]
  if not z then
    return 0, 0
  end
  local wx = z.wx0 + (zx or 0.5) * z.w
  local wy = z.wy0 + (1 - (zy or 0.5)) * z.h
  return wx, wy
end

Data.worldOf = worldOf

-- id, name, kind, faction, uiMapID, zx, zy, taxiName, aliases
-- kind: city, town, flight, port, tram, dungeon, raid, zone
local rawNodes = {
  -- Alliance EK
  { "stormwind", "Stormwind City", "city", "Alliance", 1453, 0.50, 0.62, nil, { "sw", "stormwind city" } },
  { "stormwind_fp", "Stormwind Gryphon Master", "flight", "Alliance", 1453, 0.71, 0.72, "Stormwind, Elwynn", { "stormwind fp" } },
  { "stormwind_tram", "Stormwind Deeprun Tram", "tram", "Alliance", 1453, 0.63, 0.08, nil, { "deeprun tram", "tram" } },
  { "goldshire", "Goldshire", "town", "Alliance", 1429, 0.42, 0.66, nil, { "goldshire", "lion's pride inn" } },
  { "northshire", "Northshire Abbey", "town", "Alliance", 1429, 0.48, 0.42, nil, { "northshire" } },
  { "sentinel_hill", "Sentinel Hill", "town", "Alliance", 1436, 0.56, 0.53, nil, { "sentinel hill", "westfall" } },
  { "sentinel_hill_fp", "Sentinel Hill Gryphon Master", "flight", "Alliance", 1436, 0.56, 0.53, "Sentinel Hill, Westfall", {} },
  { "lakeshire", "Lakeshire", "town", "Alliance", 1433, 0.27, 0.59, nil, { "lakeshire", "redridge" } },
  { "lakeshire_fp", "Lakeshire Gryphon Master", "flight", "Alliance", 1433, 0.27, 0.59, "Lakeshire, Redridge", {} },
  { "darkshire", "Darkshire", "town", "Alliance", 1431, 0.77, 0.44, nil, { "darkshire", "duskwood" } },
  { "darkshire_fp", "Darkshire Gryphon Master", "flight", "Alliance", 1431, 0.77, 0.44, "Darkshire, Duskwood", {} },
  { "nethergarde", "Nethergarde Keep", "town", "Alliance", 1419, 0.65, 0.19, nil, { "nethergarde", "nethergarde keep" } },
  { "nethergarde_fp", "Nethergarde Keep Gryphon Master", "flight", "Alliance", 1419, 0.65, 0.19, "Nethergarde Keep, Blasted Lands", {} },
  { "morgans_vigil", "Morgan's Vigil", "town", "Alliance", 1428, 0.84, 0.68, nil, { "morgan's vigil", "morgans vigil" } },
  { "morgans_vigil_fp", "Morgan's Vigil Gryphon Master", "flight", "Alliance", 1428, 0.84, 0.68, "Morgan's Vigil, Burning Steppes", {} },
  { "ironforge", "Ironforge", "city", "Alliance", 1455, 0.55, 0.48, nil, { "if", "ironforge" } },
  { "ironforge_fp", "Ironforge Gryphon Master", "flight", "Alliance", 1455, 0.55, 0.48, "Ironforge, Dun Morogh", {} },
  { "ironforge_tram", "Ironforge Deeprun Tram", "tram", "Alliance", 1455, 0.76, 0.51, nil, {} },
  { "kharanos", "Kharanos", "town", "Alliance", 1426, 0.47, 0.52, nil, { "kharanos" } },
  { "thelsamar", "Thelsamar", "town", "Alliance", 1432, 0.34, 0.51, nil, { "thelsamar", "loch modan" } },
  { "thelsamar_fp", "Thelsamar Gryphon Master", "flight", "Alliance", 1432, 0.34, 0.51, "Thelsamar, Loch Modan", {} },
  { "menethil", "Menethil Harbor", "town", "Alliance", 1437, 0.09, 0.60, nil, { "menethil", "menethil harbor" } },
  { "menethil_fp", "Menethil Harbor Gryphon Master", "flight", "Alliance", 1437, 0.09, 0.60, "Menethil Harbor, Wetlands", {} },
  { "menethil_dock", "Menethil Harbor Docks", "port", "Alliance", 1437, 0.05, 0.63, nil, {} },
  { "southshore", "Southshore", "town", "Alliance", 1424, 0.50, 0.52, nil, { "southshore", "hillsbrad" } },
  { "southshore_fp", "Southshore Gryphon Master", "flight", "Alliance", 1424, 0.49, 0.52, "Southshore, Hillsbrad", {} },
  { "refuge_pointe", "Refuge Pointe", "town", "Alliance", 1417, 0.46, 0.47, nil, { "refuge pointe", "refuge point" } },
  { "refuge_pointe_fp", "Refuge Pointe Gryphon Master", "flight", "Alliance", 1417, 0.46, 0.47, "Refuge Pointe, Arathi", {} },
  { "aerie_peak", "Aerie Peak", "town", "Alliance", 1425, 0.14, 0.48, nil, { "aerie peak" } },
  { "aerie_peak_fp", "Aerie Peak Gryphon Master", "flight", "Alliance", 1425, 0.14, 0.48, "Aerie Peak, Hinterlands", {} },
  { "chillwind", "Chillwind Camp", "town", "Alliance", 1422, 0.43, 0.85, nil, { "chillwind", "chillwind camp" } },
  { "chillwind_fp", "Chillwind Camp Gryphon Master", "flight", "Alliance", 1422, 0.43, 0.85, "Chillwind Camp, Western Plaguelands", {} },

  -- Horde EK
  { "undercity", "Undercity", "city", "Horde", 1458, 0.66, 0.44, nil, { "uc", "undercity" } },
  { "undercity_fp", "Undercity Bat Handler", "flight", "Horde", 1458, 0.63, 0.48, "Undercity, Tirisfal", {} },
  { "uc_zeppelin", "Tirisfal Zeppelin Tower", "port", "Horde", 1420, 0.61, 0.59, nil, { "uc zeppelin" } },
  { "ruins_of_lordaeron", "Ruins of Lordaeron", "zone", "Horde", 1420, 0.62, 0.67, nil, { "ruins of lordaeron", "lordaeron", "uc courtyard" } },
  { "brill", "Brill", "town", "Horde", 1420, 0.61, 0.52, nil, { "brill" } },
  { "sepulcher", "The Sepulcher", "town", "Horde", 1421, 0.45, 0.42, nil, { "sepulcher", "the sepulcher", "silverpine" } },
  { "sepulcher_fp", "The Sepulcher Bat Handler", "flight", "Horde", 1421, 0.45, 0.42, "The Sepulcher, Silverpine Forest", {} },
  { "tarren_mill", "Tarren Mill", "town", "Horde", 1424, 0.60, 0.19, nil, { "tarren mill" } },
  { "tarren_mill_fp", "Tarren Mill Bat Handler", "flight", "Horde", 1424, 0.60, 0.19, "Tarren Mill, Hillsbrad", {} },
  { "hammerfall", "Hammerfall", "town", "Horde", 1417, 0.73, 0.36, nil, { "hammerfall" } },
  { "hammerfall_fp", "Hammerfall Wind Rider Master", "flight", "Horde", 1417, 0.73, 0.36, "Hammerfall, Arathi", {} },
  { "kargath", "Kargath", "town", "Horde", 1418, 0.04, 0.45, nil, { "kargath" } },
  { "kargath_fp", "Kargath Wind Rider Master", "flight", "Horde", 1418, 0.04, 0.45, "Kargath, Badlands", {} },
  { "gromgol", "Grom'gol Base Camp", "town", "Horde", 1434, 0.32, 0.29, nil, { "gromgol", "grom'gol", "grom gol" } },
  { "gromgol_fp", "Grom'gol Wind Rider Master", "flight", "Horde", 1434, 0.32, 0.29, "Grom'gol, Stranglethorn", {} },
  { "gromgol_zeppelin", "Grom'gol Zeppelin Tower", "port", "Horde", 1434, 0.31, 0.30, nil, {} },
  { "stonard", "Stonard", "town", "Horde", 1435, 0.46, 0.55, nil, { "stonard" } },
  { "stonard_fp", "Stonard Wind Rider Master", "flight", "Horde", 1435, 0.46, 0.55, "Stonard, Swamp of Sorrows", {} },
  { "flame_crest", "Flame Crest", "town", "Horde", 1428, 0.66, 0.24, nil, { "flame crest" } },
  { "flame_crest_fp", "Flame Crest Wind Rider Master", "flight", "Horde", 1428, 0.66, 0.24, "Flame Crest, Burning Steppes", {} },
  { "revantusk", "Revantusk Village", "town", "Horde", 1425, 0.82, 0.80, nil, { "revantusk", "revantusk village" } },
  { "revantusk_fp", "Revantusk Village Wind Rider Master", "flight", "Horde", 1425, 0.82, 0.80, "Revantusk Village, Hinterlands", {} },

  -- Neutral EK
  { "booty_bay", "Booty Bay", "town", "Neutral", 1434, 0.27, 0.77, nil, { "booty bay", "bb" } },
  { "booty_bay_fp", "Booty Bay Flight Master", "flight", "Neutral", 1434, 0.27, 0.77, "Booty Bay, Stranglethorn", {} },
  { "booty_bay_dock", "Booty Bay Docks", "port", "Neutral", 1434, 0.26, 0.73, nil, {} },
  { "thorium_point", "Thorium Point", "town", "Neutral", 1427, 0.38, 0.31, nil, { "thorium point" } },
  { "thorium_point_fp", "Thorium Point Flight Master", "flight", "Neutral", 1427, 0.38, 0.31, "Thorium Point, Searing Gorge", {} },
  { "lights_hope", "Light's Hope Chapel", "town", "Neutral", 1423, 0.81, 0.59, nil, { "light's hope", "lights hope", "lhc" } },
  { "lights_hope_fp", "Light's Hope Chapel Flight Master", "flight", "Neutral", 1423, 0.81, 0.59, "Light's Hope Chapel, Eastern Plaguelands", {} },

  -- Kalimdor Alliance
  { "darnassus", "Darnassus", "city", "Alliance", 1457, 0.40, 0.42, nil, { "darn", "darnassus" } },
  { "darnassus_fp", "Darnassus Hippogryph Master", "flight", "Alliance", 1457, 0.68, 0.45, "Darnassus, Teldrassil", {} },
  { "ruttheran", "Rut'theran Village", "town", "Alliance", 1438, 0.55, 0.91, nil, { "rut'theran", "ruttheran" } },
  { "ruttheran_fp", "Rut'theran Village Hippogryph Master", "flight", "Alliance", 1438, 0.58, 0.94, "Rut'theran Village, Teldrassil", {} },
  { "ruttheran_dock", "Rut'theran Village Dock", "port", "Alliance", 1438, 0.55, 0.96, nil, {} },
  { "auberdine", "Auberdine", "town", "Alliance", 1439, 0.37, 0.44, nil, { "auberdine", "darkshore" } },
  { "auberdine_fp", "Auberdine Hippogryph Master", "flight", "Alliance", 1439, 0.36, 0.45, "Auberdine, Darkshore", {} },
  { "auberdine_dock", "Auberdine Docks", "port", "Alliance", 1439, 0.33, 0.40, nil, {} },
  { "astranaar", "Astranaar", "town", "Alliance", 1440, 0.34, 0.48, nil, { "astranaar" } },
  { "astranaar_fp", "Astranaar Hippogryph Master", "flight", "Alliance", 1440, 0.34, 0.48, "Astranaar, Ashenvale", {} },
  { "stonetalon_peak", "Stonetalon Peak", "town", "Alliance", 1442, 0.36, 0.07, nil, { "stonetalon peak" } },
  { "stonetalon_peak_fp", "Stonetalon Peak Hippogryph Master", "flight", "Alliance", 1442, 0.36, 0.07, "Stonetalon Peak, Stonetalon Mountains", {} },
  { "nijels_point", "Nijel's Point", "town", "Alliance", 1443, 0.65, 0.10, nil, { "nijel's point", "nijels point" } },
  { "nijels_point_fp", "Nijel's Point Hippogryph Master", "flight", "Alliance", 1443, 0.65, 0.10, "Nijel's Point, Desolace", {} },
  { "thalanaar", "Thalanaar", "town", "Alliance", 1444, 0.90, 0.46, nil, { "thalanaar" } },
  { "thalanaar_fp", "Thalanaar Hippogryph Master", "flight", "Alliance", 1444, 0.90, 0.46, "Thalanaar, Feralas", {} },
  { "feathermoon", "Feathermoon Stronghold", "town", "Alliance", 1444, 0.30, 0.43, nil, { "feathermoon", "feathermoon stronghold" } },
  { "feathermoon_fp", "Feathermoon Hippogryph Master", "flight", "Alliance", 1444, 0.30, 0.43, "Feathermoon, Feralas", {} },
  { "theramore", "Theramore Isle", "town", "Alliance", 1445, 0.67, 0.51, nil, { "theramore", "theramore isle" } },
  { "theramore_fp", "Theramore Gryphon Master", "flight", "Alliance", 1445, 0.67, 0.51, "Theramore, Dustwallow Marsh", {} },
  { "theramore_dock", "Theramore Docks", "port", "Alliance", 1445, 0.71, 0.56, nil, {} },
  { "talrendis", "Talrendis Point", "town", "Alliance", 1447, 0.12, 0.78, nil, { "talrendis", "talrendis point" } },
  { "talrendis_fp", "Talrendis Point Hippogryph Master", "flight", "Alliance", 1447, 0.12, 0.78, "Talrendis Point, Azshara", {} },
  { "moonglade_alliance_fp", "Moonglade Hippogryph Master", "flight", "Alliance", 1450, 0.44, 0.45, "Moonglade, Moonglade", { "moonglade fp" } },

  -- Kalimdor Horde
  { "orgrimmar", "Orgrimmar", "city", "Horde", 1454, 0.52, 0.64, nil, { "org", "orgrimmar" } },
  { "orgrimmar_fp", "Orgrimmar Wind Rider Master", "flight", "Horde", 1454, 0.45, 0.64, "Orgrimmar, Durotar", {} },
  { "org_zeppelin", "Durotar Zeppelin Towers", "port", "Horde", 1411, 0.50, 0.12, nil, { "org zeppelin" } },
  { "razor_hill", "Razor Hill", "town", "Horde", 1411, 0.52, 0.40, nil, { "razor hill" } },
  { "crossroads", "The Crossroads", "town", "Horde", 1413, 0.52, 0.30, nil, { "crossroads", "xroads", "the crossroads" } },
  { "crossroads_fp", "Crossroads Wind Rider Master", "flight", "Horde", 1413, 0.51, 0.30, "Crossroads, The Barrens", {} },
  { "camp_taurajo", "Camp Taurajo", "town", "Horde", 1413, 0.45, 0.59, nil, { "camp taurajo", "taurajo" } },
  { "camp_taurajo_fp", "Camp Taurajo Wind Rider Master", "flight", "Horde", 1413, 0.45, 0.59, "Camp Taurajo, The Barrens", {} },
  { "thunder_bluff", "Thunder Bluff", "city", "Horde", 1456, 0.40, 0.58, nil, { "tb", "thunder bluff", "thunderbluff" } },
  { "thunder_bluff_fp", "Thunder Bluff Wind Rider Master", "flight", "Horde", 1456, 0.47, 0.50, "Thunder Bluff, Mulgore", {} },
  { "bloodhoof", "Bloodhoof Village", "town", "Horde", 1412, 0.47, 0.60, nil, { "bloodhoof" } },
  { "splintertree", "Splintertree Post", "town", "Horde", 1440, 0.73, 0.61, nil, { "splintertree", "splintertree post" } },
  { "splintertree_fp", "Splintertree Post Wind Rider Master", "flight", "Horde", 1440, 0.73, 0.61, "Splintertree Post, Ashenvale", {} },
  { "zoramgar", "Zoram'gar Outpost", "town", "Horde", 1440, 0.12, 0.34, nil, { "zoram'gar", "zoramgar" } },
  { "zoramgar_fp", "Zoram'gar Wind Rider Master", "flight", "Horde", 1440, 0.12, 0.34, "Zoram'gar Outpost, Ashenvale", {} },
  { "sun_rock", "Sun Rock Retreat", "town", "Horde", 1442, 0.45, 0.60, nil, { "sun rock", "sun rock retreat" } },
  { "sun_rock_fp", "Sun Rock Retreat Wind Rider Master", "flight", "Horde", 1442, 0.45, 0.60, "Sun Rock Retreat, Stonetalon Mountains", {} },
  { "shadowprey", "Shadowprey Village", "town", "Horde", 1443, 0.25, 0.75, nil, { "shadowprey" } },
  { "shadowprey_fp", "Shadowprey Village Wind Rider Master", "flight", "Horde", 1443, 0.25, 0.75, "Shadowprey Village, Desolace", {} },
  { "camp_mojache", "Camp Mojache", "town", "Horde", 1444, 0.75, 0.44, nil, { "camp mojache", "mojache" } },
  { "camp_mojache_fp", "Camp Mojache Wind Rider Master", "flight", "Horde", 1444, 0.75, 0.44, "Camp Mojache, Feralas", {} },
  { "freewind", "Freewind Post", "town", "Horde", 1441, 0.45, 0.50, nil, { "freewind", "freewind post" } },
  { "freewind_fp", "Freewind Post Wind Rider Master", "flight", "Horde", 1441, 0.45, 0.50, "Freewind Post, Thousand Needles", {} },
  { "brackenwall", "Brackenwall Village", "town", "Horde", 1445, 0.36, 0.32, nil, { "brackenwall" } },
  { "brackenwall_fp", "Brackenwall Village Wind Rider Master", "flight", "Horde", 1445, 0.36, 0.32, "Brackenwall Village, Dustwallow Marsh", {} },
  { "bloodvenom", "Bloodvenom Post", "town", "Horde", 1448, 0.34, 0.53, nil, { "bloodvenom", "bloodvenom post" } },
  { "bloodvenom_fp", "Bloodvenom Post Wind Rider Master", "flight", "Horde", 1448, 0.34, 0.53, "Bloodvenom Post, Felwood", {} },
  { "valormok", "Valormok", "town", "Horde", 1447, 0.22, 0.50, nil, { "valormok" } },
  { "valormok_fp", "Valormok Wind Rider Master", "flight", "Horde", 1447, 0.22, 0.50, "Valormok, Azshara", {} },
  { "moonglade_horde_fp", "Moonglade Wind Rider Master", "flight", "Horde", 1450, 0.32, 0.67, "Moonglade, Moonglade", {} },

  -- Neutral Kalimdor
  { "ratchet", "Ratchet", "town", "Neutral", 1413, 0.62, 0.37, nil, { "ratchet" } },
  { "ratchet_fp", "Ratchet Flight Master", "flight", "Neutral", 1413, 0.63, 0.37, "Ratchet, The Barrens", {} },
  { "ratchet_dock", "Ratchet Docks", "port", "Neutral", 1413, 0.63, 0.38, nil, {} },
  { "gadgetzan", "Gadgetzan", "town", "Neutral", 1446, 0.51, 0.29, nil, { "gadgetzan", "gadge" } },
  { "gadgetzan_fp", "Gadgetzan Flight Master", "flight", "Neutral", 1446, 0.51, 0.29, "Gadgetzan, Tanaris", {} },
  { "everlook", "Everlook", "town", "Neutral", 1452, 0.62, 0.36, nil, { "everlook" } },
  { "everlook_fp", "Everlook Flight Master", "flight", "Neutral", 1452, 0.62, 0.36, "Everlook, Winterspring", {} },
  { "marshals", "Marshal's Refuge", "town", "Neutral", 1449, 0.45, 0.08, nil, { "marshal's refuge", "marshals" } },
  { "marshals_fp", "Marshal's Refuge Flight Master", "flight", "Neutral", 1449, 0.45, 0.08, "Marshal's Refuge, Un'Goro Crater", {} },
  { "cenarion_hold", "Cenarion Hold", "town", "Neutral", 1451, 0.51, 0.36, nil, { "cenarion hold", "cenarion" } },
  { "cenarion_hold_fp", "Cenarion Hold Flight Master", "flight", "Neutral", 1451, 0.51, 0.36, "Cenarion Hold, Silithus", {} },
  { "moonglade", "Nighthaven", "town", "Neutral", 1450, 0.48, 0.39, nil, { "moonglade", "nighthaven" } },

  -- Dungeon / raid entrances (overworld)
  { "rfc", "Ragefire Chasm", "dungeon", "Horde", 1454, 0.52, 0.49, nil, { "rfc", "ragefire", "ragefire chasm" } },
  { "wc", "Wailing Caverns", "dungeon", "Neutral", 1413, 0.46, 0.36, nil, { "wc", "wailing caverns" } },
  { "deadmines", "The Deadmines", "dungeon", "Alliance", 1436, 0.42, 0.72, nil, { "dm", "vc", "deadmines", "the deadmines", "deadmine" } },
  { "stockades", "The Stockade", "dungeon", "Alliance", 1453, 0.51, 0.68, nil, { "stocks", "stockade", "stockades", "the stockade" } },
  { "sfk", "Shadowfang Keep", "dungeon", "Neutral", 1421, 0.45, 0.68, nil, { "sfk", "shadowfang", "shadowfang keep" } },
  { "bfd", "Blackfathom Deeps", "dungeon", "Neutral", 1440, 0.14, 0.14, nil, { "bfd", "blackfathom", "blackfathom deeps" } },
  { "gnomer", "Gnomeregan", "dungeon", "Alliance", 1426, 0.24, 0.40, nil, { "gnomer", "gnomeregan", "gnomeragan" } },
  { "rfk", "Razorfen Kraul", "dungeon", "Neutral", 1413, 0.42, 0.90, nil, { "rfk", "razorfen kraul" } },
  { "sm", "Scarlet Monastery", "dungeon", "Neutral", 1420, 0.84, 0.30, nil, { "sm", "scarlet monastery", "scarlet", "sm gy", "sm lib", "sm arm", "sm cath", "graveyard", "library", "armory", "cathedral" } },
  { "rfd", "Razorfen Downs", "dungeon", "Neutral", 1413, 0.49, 0.93, nil, { "rfd", "razorfen downs" } },
  { "uldaman", "Uldaman", "dungeon", "Neutral", 1418, 0.43, 0.12, nil, { "ulda", "uldaman" } },
  { "zf", "Zul'Farrak", "dungeon", "Neutral", 1446, 0.39, 0.20, nil, { "zf", "zulfarrak", "zul farrak", "zul'farrak" } },
  { "mara", "Maraudon", "dungeon", "Neutral", 1443, 0.29, 0.62, nil, { "mara", "maraudon" } },
  { "st", "The Temple of Atal'Hakkar", "dungeon", "Neutral", 1435, 0.70, 0.48, nil, { "st", "sunken temple", "atal'hakkar", "atalhakkar" } },
  { "brd", "Blackrock Depths", "dungeon", "Neutral", 1427, 0.35, 0.77, nil, { "brd", "blackrock depths", "blackrock depth" } },
  { "lbrs", "Lower Blackrock Spire", "dungeon", "Neutral", 1428, 0.29, 0.38, nil, { "lbrs", "brs", "blackrock spire" } },
  { "ubrs", "Upper Blackrock Spire", "raid", "Neutral", 1428, 0.29, 0.36, nil, { "ubrs" } },
  { "scholo", "Scholomance", "dungeon", "Neutral", 1422, 0.69, 0.73, nil, { "scholo", "scholomance" } },
  { "strat", "Stratholme", "dungeon", "Neutral", 1423, 0.31, 0.17, nil, { "strat", "stratholme", "strat live", "strat ud", "strat undead" } },
  { "dire_maul", "Dire Maul", "dungeon", "Neutral", 1444, 0.59, 0.44, nil, { "dire maul", "diremaul", "dmn", "dmw", "dme", "dm east", "dm west", "dm north" } },
  { "onyxia", "Onyxia's Lair", "raid", "Neutral", 1445, 0.52, 0.76, nil, { "ony", "onyxia", "onyxia's lair" } },
  { "mc", "Molten Core", "raid", "Neutral", 1427, 0.34, 0.84, nil, { "mc", "molten core" } },
  { "bwl", "Blackwing Lair", "raid", "Neutral", 1428, 0.29, 0.32, nil, { "bwl", "blackwing lair" } },
  { "zg", "Zul'Gurub", "raid", "Neutral", 1434, 0.54, 0.17, nil, { "zg", "zulgurub", "zul'gurub", "zul gurub" } },
  { "aq20", "Ruins of Ahn'Qiraj", "raid", "Neutral", 1451, 0.29, 0.93, nil, { "aq20", "ruins of ahn'qiraj", "aq ruins" } },
  { "aq40", "Temple of Ahn'Qiraj", "raid", "Neutral", 1451, 0.27, 0.95, nil, { "aq40", "aq", "temple of ahn'qiraj", "ahn'qiraj" } },
  { "naxx", "Naxxramas", "raid", "Neutral", 1423, 0.39, 0.26, nil, { "naxx", "naxxramas" } },
  { "blackrock_mountain", "Blackrock Mountain", "zone", "Neutral", 1427, 0.33, 0.80, nil, { "blackrock", "blackrock mountain", "brm" } },
}

local nodes = {}
local nodesByTaxi = {}
local nodesByAlias = {}

local function addAlias(alias, id)
  if not alias or alias == "" then
    return
  end
  nodesByAlias[Layover.Util.normalize(alias)] = id
end

for i = 1, #rawNodes do
  local r = rawNodes[i]
  local wx, wy = worldOf(r[5], r[6], r[7])
  local node = {
    id = r[1],
    name = r[2],
    kind = r[3],
    faction = r[4],
    uiMapID = r[5],
    zx = r[6],
    zy = r[7],
    taxiName = r[8],
    aliases = r[9] or {},
    wx = wx,
    wy = wy,
    continent = zones[r[5]] and zones[r[5]].continent or "EK",
  }
  nodes[node.id] = node
  addAlias(node.id, node.id)
  addAlias(node.name, node.id)
  if node.taxiName then
    nodesByTaxi[Layover.Util.normalize(node.taxiName)] = node.id
    addAlias(node.taxiName, node.id)
  end
  for a = 1, #node.aliases do
    addAlias(node.aliases[a], node.id)
  end
end

Data.nodes = nodes
Data.nodesByTaxi = nodesByTaxi
Data.nodesByAlias = nodesByAlias

-- Flight connections: { from, to, faction }. Times are derived from distance.
-- Bidirectional unless oneWay is set.
local flightPairs = {
  -- Alliance EK
  { "stormwind_fp", "sentinel_hill_fp", "Alliance" },
  { "stormwind_fp", "lakeshire_fp", "Alliance" },
  { "stormwind_fp", "darkshire_fp", "Alliance" },
  { "stormwind_fp", "nethergarde_fp", "Alliance" },
  { "sentinel_hill_fp", "darkshire_fp", "Alliance" },
  { "sentinel_hill_fp", "booty_bay_fp", "Alliance" },
  { "lakeshire_fp", "darkshire_fp", "Alliance" },
  { "lakeshire_fp", "morgans_vigil_fp", "Alliance" },
  { "darkshire_fp", "booty_bay_fp", "Alliance" },
  { "darkshire_fp", "nethergarde_fp", "Alliance" },
  { "morgans_vigil_fp", "thorium_point_fp", "Alliance" },
  { "morgans_vigil_fp", "nethergarde_fp", "Alliance" },
  { "ironforge_fp", "thelsamar_fp", "Alliance" },
  { "ironforge_fp", "menethil_fp", "Alliance" },
  { "ironforge_fp", "thorium_point_fp", "Alliance" },
  { "thelsamar_fp", "menethil_fp", "Alliance" },
  { "menethil_fp", "southshore_fp", "Alliance" },
  { "menethil_fp", "refuge_pointe_fp", "Alliance" },
  { "southshore_fp", "refuge_pointe_fp", "Alliance" },
  { "southshore_fp", "chillwind_fp", "Alliance" },
  { "refuge_pointe_fp", "aerie_peak_fp", "Alliance" },
  { "aerie_peak_fp", "chillwind_fp", "Alliance" },
  { "aerie_peak_fp", "lights_hope_fp", "Alliance" },
  { "chillwind_fp", "lights_hope_fp", "Alliance" },
  -- Horde EK
  { "undercity_fp", "sepulcher_fp", "Horde" },
  { "undercity_fp", "tarren_mill_fp", "Horde" },
  { "sepulcher_fp", "tarren_mill_fp", "Horde" },
  { "tarren_mill_fp", "hammerfall_fp", "Horde" },
  { "hammerfall_fp", "revantusk_fp", "Horde" },
  { "hammerfall_fp", "kargath_fp", "Horde" },
  { "kargath_fp", "stonard_fp", "Horde" },
  { "kargath_fp", "flame_crest_fp", "Horde" },
  { "gromgol_fp", "booty_bay_fp", "Horde" },
  { "gromgol_fp", "stonard_fp", "Horde" },
  { "stonard_fp", "flame_crest_fp", "Horde" },
  { "flame_crest_fp", "thorium_point_fp", "Horde" },
  { "undercity_fp", "lights_hope_fp", "Horde" },
  { "revantusk_fp", "lights_hope_fp", "Horde" },
  -- Alliance Kalimdor
  { "ruttheran_fp", "auberdine_fp", "Alliance" },
  { "auberdine_fp", "astranaar_fp", "Alliance" },
  { "auberdine_fp", "stonetalon_peak_fp", "Alliance" },
  { "auberdine_fp", "feathermoon_fp", "Alliance" },
  { "auberdine_fp", "talrendis_fp", "Alliance" },
  { "astranaar_fp", "stonetalon_peak_fp", "Alliance" },
  { "astranaar_fp", "talrendis_fp", "Alliance" },
  { "stonetalon_peak_fp", "nijels_point_fp", "Alliance" },
  { "nijels_point_fp", "feathermoon_fp", "Alliance" },
  { "thalanaar_fp", "feathermoon_fp", "Alliance" },
  { "thalanaar_fp", "theramore_fp", "Alliance" },
  { "thalanaar_fp", "gadgetzan_fp", "Alliance" },
  { "theramore_fp", "gadgetzan_fp", "Alliance" },
  { "theramore_fp", "ratchet_fp", "Alliance" },
  { "feathermoon_fp", "auberdine_fp", "Alliance" },
  { "moonglade_alliance_fp", "auberdine_fp", "Alliance" },
  { "moonglade_alliance_fp", "everlook_fp", "Alliance" },
  { "everlook_fp", "talrendis_fp", "Alliance" },
  { "gadgetzan_fp", "marshals_fp", "Alliance" },
  { "darnassus_fp", "ruttheran_fp", "Alliance" },
  -- Horde Kalimdor
  { "orgrimmar_fp", "crossroads_fp", "Horde" },
  { "orgrimmar_fp", "thunder_bluff_fp", "Horde" },
  { "orgrimmar_fp", "splintertree_fp", "Horde" },
  { "orgrimmar_fp", "valormok_fp", "Horde" },
  { "orgrimmar_fp", "ratchet_fp", "Horde" },
  { "crossroads_fp", "camp_taurajo_fp", "Horde" },
  { "crossroads_fp", "ratchet_fp", "Horde" },
  { "crossroads_fp", "bloodvenom_fp", "Horde" },
  { "crossroads_fp", "freewind_fp", "Horde" },
  { "crossroads_fp", "sun_rock_fp", "Horde" },
  { "crossroads_fp", "brackenwall_fp", "Horde" },
  { "thunder_bluff_fp", "camp_taurajo_fp", "Horde" },
  { "thunder_bluff_fp", "sun_rock_fp", "Horde" },
  { "thunder_bluff_fp", "zoramgar_fp", "Horde" },
  { "thunder_bluff_fp", "shadowprey_fp", "Horde" },
  { "splintertree_fp", "zoramgar_fp", "Horde" },
  { "splintertree_fp", "valormok_fp", "Horde" },
  { "sun_rock_fp", "shadowprey_fp", "Horde" },
  { "shadowprey_fp", "camp_mojache_fp", "Horde" },
  { "camp_mojache_fp", "freewind_fp", "Horde" },
  { "freewind_fp", "gadgetzan_fp", "Horde" },
  { "brackenwall_fp", "gadgetzan_fp", "Horde" },
  { "bloodvenom_fp", "moonglade_horde_fp", "Horde" },
  { "bloodvenom_fp", "everlook_fp", "Horde" },
  { "valormok_fp", "everlook_fp", "Horde" },
  { "moonglade_horde_fp", "everlook_fp", "Horde" },
  { "gadgetzan_fp", "marshals_fp", "Horde" },
  -- Neutral shared
  { "marshals_fp", "cenarion_hold_fp", "Neutral" },
  { "gadgetzan_fp", "cenarion_hold_fp", "Neutral" },
  { "thorium_point_fp", "ironforge_fp", "Alliance" },
}

local GRYPHON_YDS = 32
local GRYPHON_PAD = 16

local function flightSeconds(aId, bId)
  local a, b = nodes[aId], nodes[bId]
  local d = Layover.Util.dist(a.wx, a.wy, b.wx, b.wy)
  return math.max(40, math.floor(d / GRYPHON_YDS) + GRYPHON_PAD)
end

local edges = {}

local function addEdge(edge)
  edges[#edges + 1] = edge
end

local function addBidirectional(fromId, toId, mode, seconds, faction, extra)
  extra = extra or {}
  local fwd = {
    from = fromId,
    to = toId,
    mode = mode,
    seconds = seconds,
    faction = faction or "Neutral",
  }
  local rev = {
    from = toId,
    to = fromId,
    mode = mode,
    seconds = seconds,
    faction = faction or "Neutral",
  }
  for k, v in pairs(extra) do
    fwd[k] = v
    rev[k] = v
  end
  addEdge(fwd)
  addEdge(rev)
end

for i = 1, #flightPairs do
  local p = flightPairs[i]
  local secs = flightSeconds(p[1], p[2])
  addBidirectional(p[1], p[2], "flight", secs, p[3])
end

-- Boats: transit + average wait (cycle ~5 min => ~150s wait).
-- User-specified Classic Era routes.
addBidirectional("menethil_dock", "theramore_dock", "boat", 210 + 150, "Neutral", {
  label = "Boat: Menethil Harbor ↔ Theramore",
})
addBidirectional("menethil_dock", "auberdine_dock", "boat", 240 + 150, "Neutral", {
  label = "Boat: Menethil Harbor ↔ Auberdine",
})
addBidirectional("booty_bay_dock", "ratchet_dock", "boat", 210 + 150, "Neutral", {
  label = "Boat: Booty Bay ↔ Ratchet",
})
addBidirectional("auberdine_dock", "ruttheran_dock", "boat", 70 + 90, "Neutral", {
  label = "Boat: Auberdine ↔ Rut'theran Village",
})

-- Zeppelins: Horde only.
addBidirectional("org_zeppelin", "uc_zeppelin", "zeppelin", 240 + 150, "Horde", {
  label = "Zeppelin: Orgrimmar ↔ Undercity",
})
addBidirectional("org_zeppelin", "gromgol_zeppelin", "zeppelin", 240 + 150, "Horde", {
  label = "Zeppelin: Orgrimmar ↔ Grom'gol",
})
addBidirectional("uc_zeppelin", "gromgol_zeppelin", "zeppelin", 270 + 150, "Horde", {
  label = "Zeppelin: Undercity ↔ Grom'gol",
})

-- Deeprun Tram: Alliance-safe.
addBidirectional("stormwind_tram", "ironforge_tram", "tram", 90, "Alliance", {
  label = "Deeprun Tram: Stormwind ↔ Ironforge",
})

-- Rut'theran Village ↔ Darnassus town portal (Classic Era).
addBidirectional("ruttheran", "darnassus", "portal", 12, "Neutral", {
  label = "Take the portal: Rut'theran Village ↔ Darnassus",
})

Data.edges = edges

-- Inn / hearth bind location strings mapped onto nodes.
Data.bindNames = {
  ["stormwind city"] = "stormwind",
  ["the lion's pride inn"] = "goldshire",
  ["goldshire"] = "goldshire",
  ["ironforge"] = "ironforge",
  ["thelsamar"] = "thelsamar",
  ["menethil harbor"] = "menethil",
  ["southshore"] = "southshore",
  ["lakeshire"] = "lakeshire",
  ["darkshire"] = "darkshire",
  ["sentinel hill"] = "sentinel_hill",
  ["booty bay"] = "booty_bay",
  ["darnassus"] = "darnassus",
  ["auberdine"] = "auberdine",
  ["astranaar"] = "astranaar",
  ["theramore isle"] = "theramore",
  ["theramore"] = "theramore",
  ["orgrimmar"] = "orgrimmar",
  ["razor hill"] = "razor_hill",
  ["the crossroads"] = "crossroads",
  ["crossroads"] = "crossroads",
  ["thunder bluff"] = "thunder_bluff",
  ["undercity"] = "undercity",
  ["brill"] = "brill",
  ["the sepulcher"] = "sepulcher",
  ["tarren mill"] = "tarren_mill",
  ["grom'gol base camp"] = "gromgol",
  ["stonard"] = "stonard",
  ["light's hope chapel"] = "lights_hope",
  ["gadgetzan"] = "gadgetzan",
  ["ratchet"] = "ratchet",
  ["kharanos"] = "kharanos",
  ["bloodhoof village"] = "bloodhoof",
}

-- Mage teleports (self). Portals are not modeled as a self-route.
Data.mageTeleports = {
  ["Teleport: Stormwind"] = "stormwind",
  ["Teleport: Ironforge"] = "ironforge",
  ["Teleport: Darnassus"] = "darnassus",
  ["Teleport: Orgrimmar"] = "orgrimmar",
  ["Teleport: Undercity"] = "undercity",
  ["Teleport: Thunder Bluff"] = "thunder_bluff",
}

Data.druidTeleport = { ["Teleport: Moonglade"] = "moonglade" }

-- Faction-aware extra destination names (resolved at search time).
Data.factionDestinations = {
  hillsbrad = { Alliance = "southshore", Horde = "tarren_mill" },
  ["hillsbrad foothills"] = { Alliance = "southshore", Horde = "tarren_mill" },
  arathi = { Alliance = "refuge_pointe", Horde = "hammerfall" },
  ["arathi highlands"] = { Alliance = "refuge_pointe", Horde = "hammerfall" },
  ashenvale = { Alliance = "astranaar", Horde = "splintertree" },
  barrens = { Alliance = "ratchet", Horde = "crossroads" },
  ["the barrens"] = { Alliance = "ratchet", Horde = "crossroads" },
  wetlands = { Alliance = "menethil", Horde = "menethil" },
  ["stonetalon mountains"] = { Alliance = "stonetalon_peak", Horde = "sun_rock" },
  stonetalon = { Alliance = "stonetalon_peak", Horde = "sun_rock" },
  feralas = { Alliance = "feathermoon", Horde = "camp_mojache" },
  desolace = { Alliance = "nijels_point", Horde = "shadowprey" },
  ["dustwallow marsh"] = { Alliance = "theramore", Horde = "brackenwall" },
  dustwallow = { Alliance = "theramore", Horde = "brackenwall" },
  hinterlands = { Alliance = "aerie_peak", Horde = "revantusk" },
  ["the hinterlands"] = { Alliance = "aerie_peak", Horde = "revantusk" },
  ["silverpine forest"] = { Alliance = "sepulcher", Horde = "sepulcher" },
  silverpine = { Alliance = "sepulcher", Horde = "sepulcher" },
}

-- Zone-name extras that should resolve even if they are not a node id.
Data.zoneAliases = {
  ["elwynn forest"] = "goldshire",
  elwynn = "goldshire",
  westfall = "sentinel_hill",
  duskwood = "darkshire",
  redridge = "lakeshire",
  ["redridge mountains"] = "lakeshire",
  ["stranglethorn vale"] = "booty_bay",
  stranglethorn = "booty_bay",
  stv = "booty_bay",
  ["blasted lands"] = "nethergarde",
  ["swamp of sorrows"] = "stonard",
  ["burning steppes"] = "morgans_vigil",
  ["searing gorge"] = "thorium_point",
  badlands = "kargath",
  ["dun morogh"] = "kharanos",
  ["loch modan"] = "thelsamar",
  ["tirisfal glades"] = "ruins_of_lordaeron",
  tirisfal = "ruins_of_lordaeron",
  ["western plaguelands"] = "chillwind",
  wpl = "chillwind",
  ["eastern plaguelands"] = "lights_hope",
  epl = "lights_hope",
  darkshore = "auberdine",
  teldrassil = "ruttheran",
  durotar = "razor_hill",
  mulgore = "bloodhoof",
  tanaris = "gadgetzan",
  ["thousand needles"] = "freewind",
  ["un'goro crater"] = "marshals",
  ungero = "marshals",
  silithus = "cenarion_hold",
  winterspring = "everlook",
  felwood = "bloodvenom",
  azshara = "talrendis",
}
