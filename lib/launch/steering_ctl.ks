//SteeringControl.ks
//Handles steering during rocket ascent.
//James McConnel
// TODO allow steering to fix inclination after locking to prograde.  Currently does not adjust when it overshoots.
//FYI's :
// Orbital inclination is never reported in practice as more that 180.  
// Launching South then, is in practice indistinguishable from launching North, at least orbit wise.
// However, this script will accept larger "inclinations" in order to support launching South.
//
//Mon Jun 19 21:16:05 PDT 2017
@LAZYGLOBAL off.
{
   //Library's exportable functions
   if not (defined launch_ctl)
      global launch_ctl is lexicon().

   //Local variables
   local h0 is 0.
   local azimuth is 0.
   local progradeDirection is ship:srfprograde.
   local inclinationReached is FALSE.

   //Init
   declare function init {
      declare parameter a.
      set azimuth to a.
      set h0 to ship:altitude.
      lock steering to steeringProgram().
   }
   launch_ctl:add("init_steering", init@).


///Public functions
   declare function steeringProgram {
      //TODO Fix this reference to altitude, not robust.  But they fix these cases getting tripped toward the end of ascent.
      //What I need, is some reference to detect the next stage.
      if vang(ship:prograde:forevector, ship:srfprograde:forevector) < 5 and ship:altitude > 35000 {
         set progradeDirection to ship:prograde.
      } else {
         set progradeDirection to ship:srfprograde.
      }
      if ship:altitude < 35000 and vang(up:forevector, ship:facing:forevector) < 45 {
         if ship:altitude < h0 + 10 {
            //Prior to clearing the tower
            return ship:facing.
         }else if ship:verticalspeed < launch_param["pOverVf"] {
            //First part says, "Wait for roll to complete.", second part says, "If you started the pover already, don't come back here."
            if vang(ship:facing:starvector, heading(azimuth, 90):starvector) > 0.5 and vang(up:forevector, ship:facing:forevector) < 0.5 or ship:verticalspeed < launch_param["pOverV0"] {
               //Roll to Azimuth
               return heading(azimuth, 90).
            } else if ship:verticalspeed > launch_param["pOverV0"] {
               //Pitchover
               return heading(azimuth, 90-launch_param["pOverDeg"]).
            }
         }
      }
      //If you haven't returned yet...
      return steeringVector().
   }
   launch_ctl:add("steeringProgram", steeringProgram@).
   
   declare function steeringVector {
         local progradeVector is progradeDirection:forevector.
         if ship:verticalspeed < 0 {
            local pitchLimit is vang(up:forevector, progradeVector)*ship:altitude/70000.
            local pitchPV is ship:verticalspeed/30.
            local pitchangle is pitchLimit*((pitchPV/sqrt(1+pitchPV^2))).
            print pitchangle at(0, 6).
            print pitchlimit at(0, 7).
            set progradeVector to progradeDirection:forevector*angleaxis(pitchAngle, progradeDirection:starvector).
         }
         if inclinationReached {
            return progradeVector.
         } else if ship:orbit:inclination >= launch_param["inclination"]-0.001 {
            set inclinationReached to TRUE.
            return progradeVector.
         } else {
            local progradePitch is 90-vectorangle(up:forevector, progradeVector).
            return heading(azimuth, progradePitch). 
         }
   }
}

