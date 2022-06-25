@lazyglobal off.
{
   global steering_functions is lexicon().

   steering_functions:add("mode", "launch").

   // "Linear Tangent Gravity Turn": The pitchover follows a linear tangent curve.
   // See lib/physics.ks for the linear tangent function used.
   steering_functions:add("LTGT", {
      declare parameter azimuth, h0.
      if steering_functions["mode"] = "launch" {
         //print "launch!" at(0, 6).
         print ship:altitude at(0, 7).
         print h0 at(0, 8).
         if ship:altitude > h0 +10 {
            set steering_functions["mode"] to "roll".
            return heading(azimuth,90).
         }
         return ship:facing.
      }
      if steering_functions["mode"] = "roll" {
         //print "roll" at(0, 6).
         print eta:apoapsis at(0, 7).
         if vang(ship:facing:starvector, heading(azimuth,90):starvector) < 0.5 and ship:airspeed > launch_param["pOverV0"] {
            set steering_functions["mode"] to "pitchover".
            return heading(azimuth, phys_lib["linearTan"]()).
         }
         return heading(azimuth,90).
      }
      if steering_functions["mode"] = "pitchover" {
         //print "pitchover" at(0, 6).
         //print "arctan: "+ (phys_lib["linearTan"]()) at(0, 7).
         //print "srfprograde: "+(90-vang(ship:srfprograde:forevector, up:forevector)) at(0, 8).
         //print "prograde: "+(90-vang(ship:prograde:forevector, up:forevector)) at(0, 9).
         //print "facing: "+(90-vang(ship:facing:forevector, up:forevector)) at(0, 10).
         if vang(ship:srfprograde:forevector, up:forevector) > launch_param["pOverDeg"] and ship:airspeed > launch_param["pOverVf"] {
            set steering_functions["mode"] to "gravity turn".
            return ship:srfprograde.
         }
         return heading(azimuth, phys_lib["linearTan"]()).
      }
      if steering_functions["mode"] = "gravity turn" {
         //print "gravity turn" at(0, 6).
         //print "arctan: "+ (phys_lib["linearTan"]()) at(0, 7).
         //print "srfprograde: "+(90-vang(ship:srfprograde:forevector, up:forevector)) at(0, 8).
         //print "prograde: "+(90-vang(ship:prograde:forevector, up:forevector)) at(0, 9).
         //print "facing: "+(90-vang(ship:facing:forevector, up:forevector)) at(0, 10).
         //print "ref: "+(90-vang(ship:prograde:forevector, up:forevector)) at(0, 13).
         return ship:srfprograde.
      }
      
   }).

   // "Linear Tangent" Ship is steered following a linear tangent function.  ship:srfprograde is ignored.
   // See lib/physics.ks for the linear tangent function used.
   steering_functions:add("linearTangent", {
      declare parameter azimuth, h0.
      if steering_functions["mode"] = "launch" {
         //print "launch!" at(0, 6).
         print ship:altitude at(0, 7).
         print h0 at(0, 8).
         if ship:altitude > h0 +10 {
            set steering_functions["mode"] to "roll".
            return heading(azimuth,90).
         }
         return ship:facing.
      }
      if steering_functions["mode"] = "roll" {
         //print "roll" at(0, 6).
         print eta:apoapsis at(0, 7).
         if vang(ship:facing:starvector, heading(azimuth,90):starvector) < 0.5 and ship:airspeed > launch_param["pOverV0"] {
            set steering_functions["mode"] to "pitchover".
            return heading(azimuth, phys_lib["linearTan"]()).
         }
         return heading(azimuth,90).
      }
      if steering_functions["mode"] = "pitchover" {
         //print "pitchover" at(0, 6).
         //print "arctan: "+ (phys_lib["linearTan"]()) at(0, 7).
         //print "srfprograde: "+(90-vang(ship:srfprograde:forevector, up:forevector)) at(0, 8).
         //print "prograde: "+(90-vang(ship:prograde:forevector, up:forevector)) at(0, 9).
         //print "facing: "+(90-vang(ship:facing:forevector, up:forevector)) at(0, 10).
         if vang(ship:srfprograde:forevector, up:forevector) > launch_param["pOverDeg"] and ship:airspeed > launch_param["pOverVf"] {
            set steering_functions["mode"] to "gravity turn".
            return heading(azimuth, phys_lib["linearTan"]()).
         }
         return heading(azimuth, phys_lib["linearTan"]()).
      }
      if steering_functions["mode"] = "gravity turn" {
         //print "gravity turn" at(0, 6).
         //print "arctan: "+ (phys_lib["linearTan"]()) at(0, 7).
         //print "srfprograde: "+(90-vang(ship:srfprograde:forevector, up:forevector)) at(0, 8).
         //print "prograde: "+(90-vang(ship:prograde:forevector, up:forevector)) at(0, 9).
         //print "facing: "+(90-vang(ship:facing:forevector, up:forevector)) at(0, 10).
         //print "ref: "+(90-vang(ship:prograde:forevector, up:forevector)) at(0, 13).
         return heading(azimuth, phys_lib["linearTan"]()).
      }
      
   }).

   // Old reliable
   steering_functions:add("atmospheric", {
      declare parameter azimuth, h0.

      ///From launch to pitchover complete
      if ship:altitude < ship:body:atm:height/2 and
         vang(up:forevector, ship:facing:forevector) < launch_param["pOverDeg"]*2 and
         // ^ Don't activate after pitchover complete.  \/ Do not end until pitchover complete.
         (ship:verticalspeed < launch_param["pOverVf"] or vang(up:forevector, ship:srfprograde:forevector) < launch_param["pOverDeg"]) {
         if ship:altitude < h0 + 10 {
            //Prior to clearing the tower
            return ship:facing.
         }else {
            //First part says, "Wait for roll to complete.", second part says, "If you started the pover already, don't come back here."
            if vang(ship:facing:starvector, heading(azimuth, 90):starvector) > 0.5 and
               vang(up:forevector, ship:facing:forevector) < 0.5 or
               ship:verticalspeed < launch_param["pOverV0"] {
               //Roll to Azimuth
               return heading(azimuth, 90).
            } else if ship:verticalspeed > launch_param["pOverV0"] {
               //Pitchover
               return heading(azimuth, 90-launch_param["pOverDeg"]).
            }
         }
      }
      local progradeDirection is ship:srfprograde.
      if vang(ship:prograde:forevector, ship:srfprograde:forevector) < 4 and ((not(ship:body:atm:exists)) or ship:altitude > ship:body:atm:height/2) {
         set progradeDirection to ship:prograde.
      }
      local progradeVector is progradeDirection:forevector.
      //if ship:velocity:orbit:mag > 500 and ship:verticalspeed < 100 and ship:periapsis < ship:body:atm:height/2 and (eta:apoapsis > eta:periapsis or eta:apoapsis < 40) { // 
      if ship:velocity:orbit:mag > 500 and ship:periapsis < ship:body:atm:height/2 and (eta:apoapsis > eta:periapsis or eta:apoapsis < 40) { // 
         /// Attempts to compensate for not reaching orbit by the time apoapsis is reached.  ///
         local pitchLimit is min(45, vang(up:forevector, progradeVector)*(ship:altitude/ship:body:atm:height)).
         local twr is ship:availablethrust/(ship:mass*(ship:body:mu/((ship:body:radius+ship:altitude)^2))).
         local criticalRatio is (1/(max(1, ship:verticalspeed/40))+1/max(1, min(eta:apoapsis, ship:orbit:period-eta:apoapsis)))/2. // Closer apo is to target, less the pitch.
         //local criticalRatio is (1-ship:apoapsis/launch_param["targetApo"]). // Closer apo is to target, less the pitch.
         //local criticalSpeed is max(ship:verticalspeed, 50*(1-ship:apoapsis/launch_param["targetApo"])). // Decrease pitch as vertical speed rises.
         // Pitch up sufficient to have a vertical TWR = 1.
         //local pitchAngle is -1*min(pitchLimit, max(0, arcsin(1/max(1,twr))*(1-max(0,ship:verticalspeed)/criticalSpeed))).
         local pitchAngle is -1*min(pitchLimit, max(0, arcsin(1/max(1,twr))*criticalRatio)).
         set progradeVector to progradeDirection:forevector*angleaxis(pitchAngle, progradeDirection:starvector).
      }
      // Everything above is a modification to the progradeVector.  What follows returns the final steering output.
      if ship:orbit:inclination >= launch_param["inclination"]-0.001 {
         return progradeVector.
      } else {
         local progradePitch is max(0, 90-vectorangle(up:forevector, progradeVector)).
         return heading(azimuth, progradePitch). 
      }
   }). 

   steering_functions:add("munar", {
      if ship:verticalspeed < ship:velocity:orbit:mag*0.05 and alt:radar < 1000 {
         return up:forevector.
      }
     
      local progradeVector is ship:prograde:forevector.
      if ship:verticalspeed < 0 {
         local pitchLimit is vang(up:forevector, progradeVector).
         local twr is ship:availablethrust/(ship:mass*(ship:body:mu/((ship:body:radius+ship:altitude)^2))).
         // Pitch up sufficient to have a vertical TWR = 1.
         local pitchAngle is -1*min(pitchLimit, arcsin(1/max(1,twr))).
         set progradeVector to progradeDirection:forevector*angleaxis(pitchAngle, progradeDirection:starvector).
         return progradeVector.
       } else {
         return progradeVector*angleaxis(90-vang(up:forvector, progradeVector), ship:prograde:starvector).
       }
     }). 
}
