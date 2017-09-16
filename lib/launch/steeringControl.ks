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
   local progradeVector is ship:srfprograde.
   local inclinationReached is FALSE.

   //Init
   declare function init {
      declare parameter a.
      set azimuth to a.
      set h0 to ship:altitude.
   }
   launch_ctl:add("init_steering", init@).


///Public functions
   declare function steeringProgram {
      //Prior to clearing the tower
      if ship:altitude < h0 + 10 {
         return ship:facing.
         //TODO Fix these references to altitude, not robust.  But they fix these cases getting tripped toward the end of ascent.
         //What I need, is some reference to detect the next stage.
      //Roll to Azimuth
      }else if ship:airspeed < launch_param["pOverV0"] OR (vang(ship:facing:starvector, heading(azimuth, 90):starvector) > 0.5 AND ship:apoapsis < 35000) {
         return heading(azimuth, 90).
      //Pitchover
      }else if ship:apoapsis < 35000 AND ship:airspeed < launch_param["pOverVf"] {
         return heading(azimuth, 90-launch_param["pOverDeg"]).
      }else {
          //Change ProgradeVector
         if ship:altitude >= 35000 {
            set progradeVector to ship:prograde.
         } else set progradeVector to ship:srfprograde.
         local progradePitch is 90-vectorangle(up:forevector, progradeVector:forevector).
         if inclinationReached {
            return progradeVector.
         } else if ship:orbit:inclination >= launch_param["inclination"]-0.001 {
            set inclinationReached to TRUE.
            return progradeVector.
         } else {
            return heading(azimuth, progradePitch). 
         }
      }
   }
   launch_ctl:add("steeringProgram", steeringProgram@).
}
