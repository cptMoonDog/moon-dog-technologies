@lazyglobal off.
/// This library's list of  exported functions.
if not (defined launch_ctl)
   global launch_ctl is lexicon().

runpath("0:/lib/launch/rangeControl.ks").
runpath("0:/lib/launch/stagingControl.ks").
runpath("0:/lib/launch/steeringControl.ks").
runpath("0:/lib/launch/throttleControl.ks").

{

   global launch_param is lexicon().

   declare function init_system {
      parameter p.
      set launch_param to p.
      
      launch_ctl["init_range"]().
      //Staging system does not require initialization.
      launch_ctl["init_steering"]().
      launch_ctl["init_throttle"]().
   }
   launch_ctl:add("init", init_system@).

   local count is 0.
   ///The ascent program itself.
   declare function ascentProgram {
      print "." at(count, 22).
      set count to count+1.
      launch_ctl["staging"](true, true).
      return launch_ctl["throttle_monitor"]().
   }
   launch_ctl:add("ascent_monitor", ascentProgram@).
}
