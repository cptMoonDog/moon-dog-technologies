{
   global transfer_ctl is lexicon().
   if not (defined phys_lib) 
      if not (defined kernel_ctl) runpath("0:/lib/physics.ks"). 
      else kernel_ctl["import-lib"]("lib/physics").


   declare function transfer_dV {
      declare parameter origin.
      declare parameter target.
      
      if origin:istype("String") {set origin to body(origin).}
      local startAlt is origin:altitudeof(positionat(ship, etaPhaseAngle())).

      local transferSMA is phys_lib["sma"](origin, startAlt, target:altitude).

      local txfrVel is phys_lib["VatAlt"](origin, startAlt, transferSMA).
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
         set pa to phaseAngle(ship:orbit:semimajoraxis, t:orbit:semimajoraxis).
         set rateTarget to 360/t:orbit:period.
      } else {
         set pa to phaseAngle(ship:orbit:semimajoraxis, t).
         set rateTarget to 0.
      }
      
      local current is currentPhaseAngle(t).

      local diff is  0.
      if pa > current {
         set diff to 360+current-pa.
      } else set diff to current-pa.

      if diff < 0 set diff to diff+360.

      local tm is 0.
      if rateShip > rateTarget set tm to (diff)/(rateShip-rateTarget).
      else set tm to (diff)/(rateTarget-rateShip).

      return tm.

   }
   transfer_ctl:add("etaPhaseAngle", etaPhaseAngle@).

   declare function phaseAngle {
      parameter startAlt.
      parameter finalAlt.

      return 180 - 180/(sqrt((finalAlt/((startAlt+finalAlt)/2))^3)).
   }

}
