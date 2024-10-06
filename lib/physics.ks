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
      parameter s is 10.
      return 90-arctan(s*ship:apoapsis/(orbit_height-ship:apoapsis)).
   }
   phys_lib:add("linearTan", linearTangent@).

   declare function periodForSMA {
      parameter bod.
      parameter sma.

      return 2*constant:pi*sqrt((sma^3)/bod:mu).
   }
   phys_lib:add("period", periodForSMA@).

   declare function smaForPeriod {
      parameter bod.
      parameter t.

      return (((t/(2*constant:pi))^2)*bod:mu)^(1/3).
   }
   phys_lib:add("sma-from-period", smaForPeriod@).

   declare function visViva_altitude {
      parameter bod.
      parameter vel.
      parameter sma.

      return 2/(((vel^2)/bod:mu)+1/sma)-bod:radius.
   }

   //global g0 is constant:g0.
   
   declare function semimajoraxis {
      parameter bod.
      parameter alt1.
      parameter alt2.
      return ((alt2+bod:radius)+(alt1+bod:radius))/2.
   }
   phys_lib:add("sma", semimajoraxis@).

   declare function LANVector {
      parameter object.
      local obtObject is object.
      if not(object:istype("Orbit")) set obtObject to object:orbit.
      //Taken from KSLib.  Never would have thought of angularVel in a million years...But, does it work for a body not spinning?
      return angleaxis(obtObject:lan, obtObject:body:angularvel)*solarprimevector. 
   }
   phys_lib:add("lanVector", LANVector@).

   declare function orbitPlaneVector {
      parameter object.
      local objLan is LANVector(object).
      local obtObject is object.
      if not(object:istype("Orbit")) set obtObject to object:orbit.

      local myPlane is angleaxis(obtObject:inclination, objLan)*obtObject:body:angularvel.
      return myPlane.
   }
   phys_lib:add("obtPlaneVector", orbitPlaneVector@).

   //Returns the velocity of an object at alt in an orbit with a Semi major axis of sma.
   //For instance: for a ship in a circular 80k orbit wishing to transfer to Minmus 46400k altitude,
   //would require a deltaV increase of: visViva_velocity(body("Kerbin"), 80000, semimajoraxis(body("Kerbin"), 80000, body("Minmus"):orbit:altitude)-ship:orbit:velocity
   declare function visViva_velocity {
      parameter bod.
      parameter height.
      parameter sma.
      return sqrt(bod:mu*(2/(bod:radius+height)-1/sma)).  
   }
   phys_lib:add("VatAlt", visViva_velocity@).

   declare function OVatAlt {
      parameter bod is Kerbin.
      parameter height is 0.
      return visViva_velocity(bod, height, bod:radius+height).
   }
   phys_lib:add("OVatAlt", OVatAlt@).

   /// The SOI of the Mun is proportionally large, so this is not accurate for a return from there.
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
      local diff is abs(a2-a1).
      set diff to diff-360*floor(diff/360). // 
      if source:altitude > tgt:altitude set diff to diff-360.

      return diff.
   }

   // Returns the time until the next Hohmann transfer window.
   declare function etaPhaseAngle {
      parameter source.
      parameter tgt.
      
      local pa is phaseAngle(source:orbit:semimajoraxis, tgt:orbit:semimajoraxis).
      print "phase angle: "+pa at(0, 20).
      local current is currentPhaseAngle(source, tgt).
      print "current angle: "+current at(0, 21).

      local rateSource is 360/source:orbit:period.
      local rateTarget is 360/tgt:orbit:period.

      local diff is  0.
      if tgt:altitude > source:altitude { // tgt higher than source.
         if pa >= current { // tgt ahead, closing.
            set diff to pa-current.
         } else { // tgt behind, passing.
            set diff to 360 - abs(current-pa).
         }
         print "diff: "+diff at(0, 22).
         return diff/(rateSource-rateTarget).
      } else { // tgt lower than source.
         //set current to current - 360.
         if pa >= current { // tgt closing.
            set diff to abs(pa-current).
         } else { // tgt passing.
            set diff to 360 - abs(current-pa).
         }
         print "diff: "+diff at(0, 22).
         return diff/(rateTarget-rateSource).
      } 
   }
   phys_lib:add("etaPhaseAngle", etaPhaseAngle@).

   // Returns the eta to reach the given angle in orbit past the given node.
   declare function etaAnglePastANDN {
      parameter ANDN is "AN".
      parameter targetAngle is 90.
      if ANDN = "DN" set targetAngle to targetAngle + 180.
      local targetTA is targetAngle - ship:orbit:argumentofperiapsis.
      if targetTA < 0 set targetTA to targetTA + 360.
      local angleDistance is targetTA - ship:orbit:trueanomaly.
      if angleDistance < 0 set angleDistance to angleDistance +360.
      if ship:orbit:eccentricity < 0.001 {
         local pctOrbit is angleDistance/360.
         local etaBurnPoint is pctOrbit*ship:orbit:period.
         return etaBurnPoint.
      } else {
         local etaBurnPoint is angleDistance/(ship:angularvel:mag*180/constant:pi).
         return etaBurnPoint.
      }
   }
   phys_lib:add("etaAnglePastANDN", etaAnglePastANDN@).

}
