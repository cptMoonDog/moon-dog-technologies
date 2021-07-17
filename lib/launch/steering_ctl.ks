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

   //Init
   declare function init {
      declare parameter a.
      set azimuth to a.
      set h0 to ship:altitude.
      if not (defined steering_functions) {
         runpath("0:/config/launch/steering-functions.ks").
      }
      //if launch_param["steeringProgram"] = "LTGT"{
      //   print "locking steering to LTGT".
      //   lock steering to steering_functions["LTGT_parts"]["launch"](azimuth, h0).
      //}
      //else lock steering to steering_functions[launch_param["steeringProgram"]](azimuth, h0).
      lock steering to steering_functions["atmospheric"](azimuth, h0).
   }
   launch_ctl:add("init_steering", init@).
}

