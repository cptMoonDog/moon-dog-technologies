{
   global transfer_ctl is lexicon().

   declare function currentPhaseAngle {
      // From: https://forum.kerbalspaceprogram.com/index.php?/topic/85285-phase-angle-calculation-for-kos/
      //Assumes orbits are both in the same plane.
      local a1 is ship:orbit:lan+ship:orbit:argumentofperiapsis+ship:orbit:trueanomaly.
      local a2 is target:orbit:lan+target:orbit:argumentofperiapsis+target:orbit:trueanomaly.
      local diff is a2-a1.
      set diff to diff-360*floor(diff/360).
      return diff.
   }
   declare function etaPhaseAngle {
      local pa is phaseAngle(ship:orbit:semimajoraxis, target:orbit:semimajoraxis).
      local current is currentPhaseAngle().
      
      local diff is  0.
      if pa > current {
         set diff to 360+current-pa.
      } else set diff to current-pa.
      //local diff is  currentPhaseAngle()-phaseAngle(ship:orbit:semimajoraxis, target:orbit:semimajoraxis).
      if diff < 0 set diff to diff+360.
      // Angle rate: 360/period
      // p1+r1*t=p2+r2*t
      // r1*t=p2-p1+r2*t
      // r1*t-r2*t=p2-p1
      // t(r1-r2)=p2-p1
      // t=(p2-p1)/(r1-r2)
      // p1=0, p2=10, r1=5, r2=1 then t=2.5
      // p1=5, p2=10, r1=5, r2=1 then t=1.25 
      local rateShip is 360/ship:orbit:period.
      local rateTarget is 360/target:orbit:period.

      local t is (diff)/(rateShip-rateTarget).
      return t.

   }
   transfer_ctl:add("etaTarget", etaPhaseAngle@).

   declare function phaseAngle {
      parameter startAlt.
      parameter finalAlt.

      local p is 1/(2*sqrt((finalAlt^3)/(((startAlt+finalAlt)/2)^3))).
      local angle is p*360.
      return 180-angle.
   }

}
