runpath("0:/lib/physics.ks").
local targetBody is body("Duna").
local secondsToWindow is phys_lib["etaPhaseAngle"](body("Kerbin"), targetBody).
local orbitsToWindow is secondsToWindow/ship:orbit:period.

local hohmannTransferVelocity is phys_lib["VatAlt"](body("Sun"),
   ship:body:altitude+body("Sun"):radius,
   phys_lib["sma"](body("Sun"),
   ship:body:altitude+body("Sun"):radius,
   targetBody:altitude+body("Sun"):radius)).

local etaEjectionAngle is phys_lib["etaEjectionAngle"](hohmannTransferVelocity).
local dV is phys_lib["ejectionVelocity"](hohmannTransferVelocity)-ship:velocity:orbit:mag.

until orbitsToWindow < 1 {
   
   print "Time To Launch Window:" at(0, 3).
   print "seconds: " + secondsToWindow at(0, 4).
   print "minutes: " + secondsToWindow/60 at(0, 5).
   print "hours: " + secondsToWindow/(60*60) at(0, 6).
   print "days: " + secondsToWindow/(60*60*6) at(0, 7).
   print "orbits: " + orbitsToWindow at(0, 8).

   print "etaEjectionAngle: " + etaEjectionAngle at(0, 9).
   print "dV: " + dV at(0, 10).

   set secondsToWindow to phys_lib["etaPhaseAngle"](body("Kerbin"), targetBody).
   set orbitsToWindow to secondsToWindow/ship:orbit:period.
   set etaEjectionAngle to phys_lib["etaEjectionAngle"](hohmannTransferVelocity).
   set dV to phys_lib["ejectionVelocity"](hohmannTransferVelocity)-ship:velocity:orbit:mag.
}

add(node(time:seconds+etaEjectionAngle, 0, 0, dV)).