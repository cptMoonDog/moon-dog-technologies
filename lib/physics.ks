@LAZYGLOBAL off.
{
   global phys_lib is lexicon().

   declare function facing_compass_heading {
      local temp is (-1*ship:bearing).
      if temp < 0 return temp + 360.
      return temp. 
   }

   declare function visViva_altitude {
      parameter bod.
      parameter vel.
      parameter sma.

      return 2/(((vel^2)/bod:mu)+1/sma)-bod:radius.
   }

   global g0 is 9.80665.
   
   declare function semimajoraxis {
      parameter bod.
      parameter alt1.
      parameter alt2.
      return ((alt2+bod:radius)+(alt1+bod:radius))/2.
   }
   phys_lib:add("sma", semimajoraxis@).

   //Returns the velocity of an object at alt in an orbit with a Semi major axis of sma.
   //For instance: for a ship in a circular 80k orbit wishing to transfer to Minmus 46400k altitude,
   //would require a deltaV increase of: visViva_velocity(body("Kerbin"), 80000, semimajoraxis(body("Kerbin"), 80000, body("Minmus"):orbit:altitude)-ship:orbit:velocity
   //increase in velocity.
   declare function visViva_velocity {
      parameter bod.
      parameter alt.
      parameter sma.
      return sqrt(bod:mu*(2/(bod:radius+alt)-1/sma)).  
   }
   phys_lib:add("VatAlt", visViva_velocity@).

   declare function OVatAlt {
      parameter bod is Kerbin.
      parameter alt is 0.
      return visViva_velocity(bod, alt, bod:radius+alt).
   }
   phys_lib:add("OVatAlt", OVatAlt@).

   declare function getEjectionAngle {
            parameter targetPeriapsis is 34000.
            local vinf is (ship:body:velocity:orbit - ship:body:body:velocity:orbit):mag - phys_lib["VatAlt"](ship:body:body, ship:body:altitude, phys_lib["sma"](ship:body:body, ship:body:orbit:apoapsis, targetPeriapsis)). //365. //Should be 373.789, Defines the velocity going into the other SOI, which determines some features of the new patch.

            local r0 is ship:altitude+ship:body:radius.
            local vejection is sqrt((r0*(ship:body:soiradius*vinf^2-2*ship:body:mu)+2*ship:body:soiradius*ship:body:mu)/(r0*ship:body:soiradius)). 
            local epsilon is (vejection^2)/2 - ship:body:mu/r0.
            local h is r0*(vejection)*sin(90). //vectorcross ship position and ship velocity
            local hecc is sqrt(1+(2*epsilon*(h^2))/(ship:body:mu^2)).
            local theta is arccos(1/hecc).
            
            return 180-theta. 
   }
      
   declare function phaseAngle {
      parameter startAlt.
      parameter finalAlt.

      local p is 1/(2*sqrt((finalAlt^3)/(((startAlt+finalAlt)/2)^3))).
      local angle is p*360.
      return 180-angle.
   }

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

      // I want some time to burn my engines, so I need to lead a bit to have time
      // I'm sure there is a better way to do this, but for now...
      local minDiff is 20.
      
      local diff is  0.
      if pa > current-minDiff {
         set diff to 360+current-pa.
      } else set diff to current-pa.

      if diff < 0 set diff to diff+360.
      local rateShip is 360/ship:orbit:period.
      local rateTarget is 360/target:orbit:period.

      local t is (diff)/(rateShip-rateTarget).
      return t.

   }
   transfer_ctl:add("etaPhaseAngle", etaPhaseAngle@).
}