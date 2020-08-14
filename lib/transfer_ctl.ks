{
   global transfer_ctl is lexicon().
   if not (defined phys_lib) runpath("0:/lib/physics.ks"). 


   declare function transfer_dV {
      declare parameter origin.
      declare parameter target.
      local startAlt is body(origin):altitudeof(positionat(ship, etaPhaseAngle())).

      local transferSMA is phys_lib["sma"](body(origin), startAlt, target:altitude).

      local txfrVel is phys_lib["VatAlt"](body(origin), startAlt, transferSMA).
      local startVel is velocityat(ship, etaPhaseAngle()):orbit:mag.
      return txfrVel-startVel.
   }
   transfer_ctl:add("dv", transfer_dv@).

   declare function currentPhaseAngle {
      // From: https://forum.kerbalspaceprogram.com/index.php?/topic/85285-phase-angle-calculation-for-kos/
      //Assumes orbits are both in the same plane.
      declare parameter t is target.
      local a1 is ship:orbit:lan+ship:orbit:argumentofperiapsis+ship:orbit:trueanomaly.
      local a2 is 0.
      if t:istype("Orbitable") {
         set a2 to t:orbit:lan+t:orbit:argumentofperiapsis+t:orbit:trueanomaly.
      } else {
         set a2 to t.
      }
      
      local diff is a2-a1.
      set diff to diff-360*floor(diff/360).
      return diff.
   }

   declare function etaPhaseAngle {
      declare parameter t is target.
      local rateShip is 360/ship:orbit:period.
      local rateTarget is 0.
      local pa is 0.
      if t:istype("Orbitable") {
         set pa to phaseAngle(ship:orbit:semimajoraxis, target:orbit:semimajoraxis).
         set rateTarget to 360/target:orbit:period.
      } else {
         set pa to phaseAngle(ship:orbit:semimajoraxis, t).
         set rateTarget to 0.
      }
      
      local current is currentPhaseAngle(t).

      // I want some time to burn my engines, so I need to lead a bit to have time
      // I'm sure there is a better way to do this, but for now...
      local minDiff is 20.
      
      local diff is  0.
      if pa > current-minDiff {
         set diff to 360+current-pa.
      } else set diff to current-pa.

      if diff < 0 set diff to diff+360.

      local t is (diff)/(rateShip-rateTarget).
      return t.

   }
   transfer_ctl:add("etaPhaseAngle", etaPhaseAngle@).

   declare function phaseAngle {
      parameter startAlt.
      parameter finalAlt.

      local p is 1/(2*sqrt((finalAlt^3)/(((startAlt+finalAlt)/2)^3))).
      local angle is p*360.
      return 180-angle.
   }

}
