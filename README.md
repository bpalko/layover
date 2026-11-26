# Layover

Shortest-path travel router for **WoW Classic Era** (Vanilla 1–60), including **WoW Forever**.

Layover pairs with quest helpers such as RestedXP: it does **not** draw a floating arrow. It computes a multi-leg route (flights, boats, zeppelins, Deeprun Tram, ground travel, hearthstone, class teleports) and shows a numbered checklist with per-leg and total ETAs. Steps auto-advance as you move.

## Install

1. Download or clone this repository.
2. Copy the folder so the game sees `Interface/AddOns/Layover/Layover.toc`.
   - The folder name must be `Layover`.
3. Restart the client (or `/reload` after a full restart once it is present).
4. Optional: [TomTom](https://www.curseforge.com/wow/addons/tomtom) — if a native map pin is not set, Layover will route to the active TomTom waypoint.

`Layover.toc` targets Classic Era interface versions `11403`–`11507`.

## Using it

### Destinations

1. **Native map pin** — place a waypoint on the world map (`C_Map` / `USER_WAYPOINT_UPDATED`). Layover routes to that `(uiMapID, x, y)`.
2. **Slash command / search box**
   - `/layover <destination>` or `/lo <destination>`
   - Examples: `/lo sm`, `/lo scarlet monastery`, `/lo undercity`, `/lo ruins of lordaeron`, `/lo rfc`, `/lo dm`, `/lo brd`, `/lo strat`
3. **TomTom** — `/lo pin` uses the native pin if present, otherwise the TomTom crazy-arrow waypoint.

Other commands:

| Command | Effect |
| --- | --- |
| `/lo skip` | Mark the current step done and advance |
| `/lo clear` | Drop the active route |
| `/lo window` | Toggle the checklist |
| `/lo lock` | Lock/unlock dragging the window |
| `/lo help` | Print help |

The checklist is movable. Click a search suggestion or press Enter in the destination box to route. Use **Skip** / **Clear** on the window, or the slash commands, for manual control.

### What it models (v1)

- **Flight paths** — Classic Era Alliance, Horde, and neutral nodes, with faction rules. Discovered nodes are cached per character in `LayoverDB` whenever `TAXIMAP_OPENED` fires. Routes use **known** nodes by default. If grabbing an unknown FP along the way is faster (e.g. Southshore on an Elwynn → Tirisfal run), a tip is shown.
- **Boats** — Menethil ↔ Theramore, Menethil ↔ Auberdine, Booty Bay ↔ Ratchet, Auberdine ↔ Rut'theran (transit + average wait).
- **Zeppelins** — Orgrimmar ↔ Undercity, Orgrimmar ↔ Grom'gol, Undercity ↔ Grom'gol (Horde).
- **Deeprun Tram** — Stormwind ↔ Ironforge (Alliance).
- **Ground travel** — weighted by your effective speed (run, 60% / 100% mount, Druid Travel Form, Shaman Ghost Wolf, Hunter Aspect of the Cheetah).
- **Hearthstone** — bind location + cooldown.
- **Mage teleports** and **Druid Teleport: Moonglade** / **Shaman Astral Recall**.

Warlock summons/portals are intentionally not modeled.

Until you open a flight map (`TAXIMAP_OPENED`), Layover has no discovered FPs for that character and will prefer tram/boats/walking/hearth/teleports. Opening any gryphon/wyvern master records the network you can see.

## Architecture

Core routing is **pure Lua 5.1** with no WoW globals, so it can be tested on a laptop.

```
src/core/     graph data, destinations, movement, Dijkstra, step machine
src/wow/      C_Map, taxi scan, SavedVariables, events
src/ui/       checklist window + slash commands
Layover.lua   orchestration (routeTo / skip / clear)
```

Weights are seconds. The router runs Dijkstra twice: once on known flight nodes only, once allowing a fly-to-undiscovered-FP hop, then surfaces the cheaper discovery as a suggestion.

## Tests (offline)

Lua 5.1, no extra rocks required:

```bash
sudo apt-get install lua5.1          # or brew install lua@5.1
lua5.1 tests/run.lua                 # suite
lua5.1 tests/demo.lua                # print sample Elwynn → UC / SM routes
```

The suite covers Elwynn → Ruins of Lordaeron / Scarlet Monastery (Alliance, with and without Southshore, hearth on/off, Mage vs Warrior), boats/zeppelins/tram, known vs undiscovered FPs, aliases/fuzzy search, coordinate waypoints, step auto-advance, and faction isolation.

GitHub Actions runs the same suite on every push/PR.
