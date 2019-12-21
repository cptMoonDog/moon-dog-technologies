global steering_functions is lexicon().

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
         }else {//if ship:verticalspeed < launch_param["pOverVf"] {
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
      if vang(ship:prograde:forevector, ship:srfprograde:forevector) < 5 and ((not(ship:body:atm:exists)) or ship:altitude > ship:body:atm:height/2) {
         set progradeDirection to ship:prograde.
      }
      local progradeVector is progradeDirection:forevector.
      if ship:velocity:orbit:mag > 500 and (ship:verticalspeed < 5) {
         local pitchLimit is vang(up:forevector, progradeVector)*min(1, ship:altitude/ship:body:atm:height).
         local twr is ship:availablethrust/(ship:mass*(ship:body:mu/((ship:body:radius+ship:altitude)^2))).
         // Pitch up sufficient to have a vertical TWR = 1.
         local pitchAngle is -1*min(pitchLimit, arcsin(1/max(1,twr)))*(1-max(0, ship:verticalspeed/5)).
         set pitchAngle to pitchAngle*(abs(ship:verticalspeed)/sqrt(1+abs(ship:verticalspeed)*abs(ship:verticalspeed))).
         if twr > 1 {
            set progradeVector to progradeDirection:forevector*angleaxis(pitchAngle, progradeDirection:starvector).
         } else {
            set progradeVector to progradeDirection:forevector*angleaxis(-45, progradeDirection:starvector).
         }
         print("*ANGLE TO* SHALLOW*") at(0, 5).
         print(pitchAngle) at(0, 6).
      }
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
