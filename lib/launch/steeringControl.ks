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
   if not (defined ascent_ctl)
      global ascent_ctl is lexicon().

   //Local variables
   local ascent_parameters is lexicon("inclination", 90, "hemisphere", "north", "pOverDeg", 4, "pOverV0", 30, "pOverVf", 150).

   local h0 is 0.
   local azimuth is 0.
   local progradeVector is ship:srfprograde.
   local inclinationReached is FALSE.

   //Init
   declare function init {
      parameter a.
      if a:istype("Lexicon") {
         set ascent_parameters to a.
      }
      set h0 to ship:altitude.
      //The following is to reduce the calls to launchAzimuth.
      set azimuth to range_ctl["launchAzimuth"](ascent_parameters["inclination"], ascent_parameters["hemisphere"]).
   }
   ascent_ctl:add("init_steering", init@).


///Public functions
   declare function steeringProgram {
      //Prior to clearing the tower
      if ship:altitude < h0 + 10 {
         return ship:facing.
         //TODO Fix these references to altitude, not robust.  But they fix these cases getting tripped toward the end of ascent.
         //What I need, is some reference to detect the next stage.
      //Roll to Azimuth
      }else if ship:airspeed < ascent_parameters["pOverV0"] AND vang(ship:facing:starvector, heading(azimuth, 90):starvector) > 0.5 AND ship:apoapsis < 35000 {
         return heading(azimuth, 90).
      //Pitchover
      }else if ship:apoapsis < 35000 AND ship:airspeed < ascent_parameters["pOverVf"] {
         return heading(azimuth, 90-ascent_parameters["pOverDeg"]).
      }else {
          //Change ProgradeVector
         if ship:altitude >= 35000 {
            set progradeVector to ship:prograde.
         } else set progradeVector to ship:srfprograde.
         local progradePitch is 90-vectorangle(up:forevector, progradeVector:forevector).
         if inclinationReached {
            return progradeVector.
         } else if ship:orbit:inclination >= ascent_parameters["inclination"]-0.001 {
            set inclinationReached to TRUE.
            return progradeVector.
         } else {
            return heading(azimuth, progradePitch). 
         }
      }
   }
   ascent_ctl:add("steeringProgram", steeringProgram@).
   
///Private functions
   declare function facing_compass_heading {
      local temp is (-1*ship:bearing).
      if temp < 0 return temp + 360.
      return temp. 
   }
}
