@LAZYGLOBAL off.
{
   global phys_lib is lexicon().

   declare function facing_compass_heading {
      local temp is (-1*ship:bearing).
      if temp < 0 return temp + 360.
      return temp. 
   }

   declare function linearTangent {
      parameter orbit_height is 80000.
      return 90-arctan(9*ship:apoapsis/orbit_height).
   }
   phys_lib:add("linearTan", linearTangent@).

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

   /// The SOI of the Mun is unusually large, so this is not accurate for a return from there.
   declare function ejectionAngle {
      parameter vinf.
      
      local r0 is ship:altitude+ship:body:radius.
      local vejection is sqrt((r0*(ship:body:soiradius*vinf^2-2*ship:body:mu)+2*ship:body:soiradius*ship:body:mu)/(r0*ship:body:soiradius)). 
      local epsilon is (vejection^2)/2 - ship:body:mu/r0.
      local h is r0*(vejection)*sin(90). //vectorcross ship position and ship velocity
      local hecc is sqrt(1+(2*epsilon*(h^2))/(ship:body:mu^2)).
      local theta is arccos(1/hecc).

      return 180-theta. 
   }

   declare function etaEjectionAngle {
      parameter desiredInterplanetaryVelocity.
      local vinf is 0.
      local planetOrbitalSpeed is (ship:body:velocity:orbit - ship:body:body:velocity:orbit):mag.
      local referenceAngle is 0.
      if desiredInterplanetaryVelocity > planetOrbitalSpeed {
         set referenceAngle to angleToBodyPrograde().
         set vinf to desiredInterplanetaryVelocity - planetOrbitalSpeed.
      } else {
         set referenceAngle to angleToBodyRetro().
         set vinf to planetOrbitalSpeed - desiredInterplanetaryVelocity.
      }
      local ejectAngle is ejectionAngle(vinf).

      local diff is (referenceAngle-ejectAngle).
      if diff < 0 set diff to diff + 360.
      local rateShip is 360/ship:orbit:period.
      local rateBody is 360/ship:body:orbit:period.

      local etaBurn is (diff)/(rateShip-rateBody).
      if ship:orbit:inclination > 90 set etaBurn to diff/(rateShip+rateBody).
      return etaBurn.
   }
   phys_lib:add("etaEjectionAngle", etaEjectionAngle@).

   declare function ejectionVelocity {
      parameter desiredInterplanetaryVelocity.
      local vinf is 0.
      local planetOrbitalSpeed is (ship:body:velocity:orbit - ship:body:body:velocity:orbit):mag.
      if desiredInterplanetaryVelocity > planetOrbitalSpeed {
         set vinf to desiredInterplanetaryVelocity - planetOrbitalSpeed.
      } else {
         set vinf to planetOrbitalSpeed - desiredInterplanetaryVelocity.
      }
      local r0 is ship:altitude+ship:body:radius.
      local vejection is sqrt((r0*(ship:body:soiradius*vinf^2-2*ship:body:mu)+2*ship:body:soiradius*ship:body:mu)/(r0*ship:body:soiradius)). 
      return vejection.
   }
   phys_lib:add("ejectionVelocity", ejectionVelocity@).
   

   //The angle between the ship's position in it's orbit, and the prograde vector of the body it is orbiting.
   declare function angleToBodyPrograde {
      local bodyVelocity is ship:body:velocity:orbit - ship:body:body:velocity:orbit.
      local velPrograde is ship:velocity:orbit:mag*cos(vang(bodyVelocity, ship:velocity:orbit)).

      local angleToPrograde is (velPrograde/abs(velPrograde))*vang(bodyVelocity, up:forevector).
      if (velPrograde/abs(velPrograde)) < 0 set angleToPrograde to 360 + (velPrograde/abs(velPrograde))*vang(bodyVelocity, up:forevector).
      return angleToPrograde.
   }
   declare function angleToBodyRetro {
      local ang is angleToBodyPrograde()+180.
      if ang > 360 set ang to ang-360.
      return ang.
   }

   declare function phaseAngle {
      parameter startAlt.
      parameter finalAlt.

      local p is 1/(2*sqrt((finalAlt^3)/(((startAlt+finalAlt)/2)^3))).
      local angle is p*360.
      return 180-angle.
   }

   declare function currentPhaseAngle {
      parameter source.
      parameter tgt.
      // From: https://forum.kerbalspaceprogram.com/index.php?/topic/85285-phase-angle-calculation-for-kos/
      //Assumes orbits are both in the same plane.
      local a1 is source:orbit:lan+source:orbit:argumentofperiapsis+source:orbit:trueanomaly.
      local a2 is tgt:orbit:lan+tgt:orbit:argumentofperiapsis+tgt:orbit:trueanomaly.
      local diff is a2-a1.
      set diff to diff-360*floor(diff/360).
      return diff.
   }

   declare function etaPhaseAngle {
      parameter source.
      parameter tgt.
      
      local pa is phaseAngle(source:orbit:semimajoraxis, tgt:orbit:semimajoraxis).
      local current is currentPhaseAngle(source, tgt).

      // I want some time to burn my engines, so I need to lead a bit to have time
      // I'm sure there is a better way to do this, but for now...
      local minDiff is 20.
      
      print "current Phase Angle: "+current at(0, 1).
      print "desired Phase Angle: "+pa at(0, 2).
      local diff is  0.
      if pa > current {
         set diff to 360+current-pa.
      } else set diff to current-pa.

      if diff < 0 set diff to diff+360.
      local rateShip is 360/source:orbit:period.
      local rateTarget is 360/tgt:orbit:period.

      local t is (diff)/(rateShip-rateTarget).
      return t.

   }
   phys_lib:add("etaPhaseAngle", etaPhaseAngle@).
}
