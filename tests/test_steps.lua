local T = ...

T.describe("step auto-advance", function()
  T.it("simulates a multi-leg Alliance route from Elwynn to SM", function()
    local r = Layover.Router.route(T.allianceWarrior({
      to = "sm",
      hearthReady = false,
      southshore = true,
    }))
    T.truthy(r.ok, T.dumpRoute(r))
    T.gt(#r.steps, 2, T.dumpRoute(r))

    local state = Layover.Steps.new(r)
    T.eq(state.currentIndex, 1)
    T.falsy(state.complete)

    -- Completing the first step by arriving at its target advances the pointer.
    local first = state.steps[1]
    Layover.Steps.advance(state, {
      uiMapID = first.to.uiMapID,
      zx = first.to.zx,
      zy = first.to.zy,
      wx = first.to.wx,
      wy = first.to.wy,
    })
    T.truthy(state.steps[1].done)
    T.eq(state.currentIndex, 2)

    -- Skip the middle of the route.
    while state.currentIndex < #state.steps and not state.complete do
      Layover.Steps.skip(state)
    end
    T.eq(state.currentIndex, #state.steps)

    -- Arrive at Scarlet Monastery.
    local sm = Layover.Graph.getNode("sm")
    Layover.Steps.advance(state, {
      uiMapID = sm.uiMapID,
      zx = sm.zx,
      zy = sm.zy,
      wx = sm.wx,
      wy = sm.wy,
      zoneName = "Tirisfal Glades",
    })
    T.truthy(state.complete, "expected arrival after standing on SM")
    T.eq(state.remainingSeconds, 0)
  end)

  T.it("manual skip marks the current step skipped", function()
    local r = Layover.Router.route(T.allianceWarrior({
      to = "ironforge",
      hearthReady = false,
    }))
    local state = Layover.Steps.new(r)
    T.gt(#state.steps, 0)
    Layover.Steps.skip(state)
    T.truthy(state.steps[1].done)
    T.truthy(state.steps[1].skipped)
  end)

  T.it("clear completes every step", function()
    local r = Layover.Router.route(T.allianceWarrior({
      to = "darkshire",
      hearthReady = false,
    }))
    local state = Layover.Steps.new(r)
    Layover.Steps.clear(state)
    T.truthy(state.complete)
  end)

  T.it("flight step does not complete while on taxi", function()
    local step = {
      index = 1,
      mode = "flight",
      toId = "menethil_fp",
      to = Layover.Graph.getNode("menethil_fp"),
      done = false,
    }
    T.falsy(Layover.Steps.isComplete(step, { onTaxi = true, uiMapID = 1437, zx = 0.09, zy = 0.60 }))
    T.truthy(Layover.Steps.isComplete(step, { onTaxi = false, taxiEndedAt = "menethil_fp" }))
  end)

  T.it("boat / tram complete on destination zone", function()
    local tram = {
      index = 1,
      mode = "tram",
      toId = "ironforge_tram",
      to = Layover.Graph.getNode("ironforge_tram"),
      done = false,
    }
    T.truthy(Layover.Steps.isComplete(tram, { uiMapID = 1455, zx = 0.76, zy = 0.51 }))

    local boat = {
      index = 1,
      mode = "boat",
      toId = "auberdine_dock",
      to = Layover.Graph.getNode("auberdine_dock"),
      done = false,
    }
    T.truthy(Layover.Steps.isComplete(boat, {
      uiMapID = 1439,
      zx = 0.33,
      zy = 0.40,
      zoneName = "Darkshore",
    }))
  end)

  T.it("checklist rows expose status for the UI", function()
    local r = Layover.Router.route(T.allianceWarrior({ to = "lakeshire", hearthReady = false }))
    local state = Layover.Steps.new(r)
    local rows = Layover.Steps.checklist(state)
    T.gt(#rows, 0)
    T.eq(rows[1].status, "current")
    if rows[2] then
      T.eq(rows[2].status, "pending")
    end
    Layover.Steps.skip(state)
    rows = Layover.Steps.checklist(state)
    T.eq(rows[1].status, "skipped")
  end)

  T.it("simulate() walks a list of snapshots to completion", function()
    local r = Layover.Router.route(T.allianceWarrior({
      to = "sentinel hill",
      hearthReady = false,
    }))
    T.truthy(r.ok, T.dumpRoute(r))
    local state = Layover.Steps.new(r)
    local snaps = {}
    for i = 1, #state.steps do
      local t = state.steps[i].to
      snaps[i] = {
        uiMapID = t.uiMapID,
        zx = t.zx,
        zy = t.zy,
        wx = t.wx,
        wy = t.wy,
      }
    end
    Layover.Steps.simulate(state, snaps)
    T.truthy(state.complete)
  end)
end)
