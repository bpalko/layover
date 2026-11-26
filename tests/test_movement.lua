local T = ...

T.describe("movement", function()
  T.it("base run speed is 7 yd/s", function()
    T.eq(Layover.Movement.speedYdsPerSec({}), 7)
  end)

  T.it("60% mount is 11.2 yd/s", function()
    T.eq(Layover.Movement.speedYdsPerSec({ mounted60 = true }), 7 * 1.6)
  end)

  T.it("100% mount is 14 yd/s", function()
    T.eq(Layover.Movement.speedYdsPerSec({ mounted100 = true }), 14)
  end)

  T.it("travel form / ghost wolf is 40%", function()
    T.eq(Layover.Movement.speedYdsPerSec({ class = "DRUID", travelForm = true }), 7 * 1.4)
    T.eq(Layover.Movement.speedYdsPerSec({ class = "SHAMAN", ghostWolf = true }), 7 * 1.4)
  end)

  T.it("aspect of the cheetah is 30%", function()
    T.eq(Layover.Movement.speedYdsPerSec({ class = "HUNTER", cheetah = true }), 7 * 1.3)
  end)

  T.it("mount beats travel form", function()
    local s = Layover.Movement.speedYdsPerSec({ class = "DRUID", travelForm = true, mounted60 = true })
    T.eq(s, 7 * 1.6)
  end)

  T.it("explicit speedYdsPerSec wins", function()
    T.eq(Layover.Movement.speedYdsPerSec({ speedYdsPerSec = 12.5, mounted100 = true }), 12.5)
  end)

  T.it("formats durations", function()
    T.eq(Layover.Util.formatDuration(45), "45s")
    T.eq(Layover.Util.formatDuration(90), "1m 30s")
    T.eq(Layover.Util.formatDuration(120), "2m")
    T.eq(Layover.Util.formatDuration(3600), "1h")
  end)

  T.it("travel verb switches at mount speed", function()
    T.eq(Layover.Movement.travelVerb(7), "Walk")
    T.eq(Layover.Movement.travelVerb(11.2), "Ride")
  end)
end)
