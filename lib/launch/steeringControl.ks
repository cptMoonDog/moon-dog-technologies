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
      lock steering to steeringProgram().
   }
   launch_ctl:add("init_steering", init@).


///Public functions
   declare function steeringProgram {
      //TODO Fix this reference to altitude, not robust.  But they fix these cases getting tripped toward the end of ascent.
      //What I need, is some reference to detect the next stage.
      if ship:altitude < 35000 {
         //Prior to clearing the tower
         if ship:altitude < h0 + 10 {
            print "facing       " at(0, 5).
            return ship:facing.
         //Roll to Azimuth
         }else if ship:verticalspeed < launch_param["pOverV0"]  {
            print "90       " at(0, 5).
            return heading(azimuth, 90).
         //Pitchover
         }else if ship:verticalspeed < launch_param["pOverVf"] {
            //First part says, "Wait for roll to complete.", second part says, "If you started the pover already, don't come back here."
            if vang(ship:facing:starvector, heading(azimuth, 90):starvector) > 0.5 and vang(up:forevector, ship:facing:forevector) < 0.5 {
               print "azimuth         " at(0, 5).
               return heading(azimuth, 90).
            } else {
               print "pover         " at(0, 5).
               return heading(azimuth, 90-launch_param["pOverDeg"]).
            }
         } else {
            print "surface          " at(0, 5).
            set progradeVector to ship:srfprograde.
            return steeringVector().
         }
      }else {
         print "prograde          " at(0, 5).
         set progradeVector to ship:prograde.
         return steeringVector().
      }
   }
   launch_ctl:add("steeringProgram", steeringProgram@).
   
   declare function steeringVector {
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

