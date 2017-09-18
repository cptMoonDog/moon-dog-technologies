@lazyglobal off.
/// This library's list of  exported functions.
if not (defined launch_ctl)
   global launch_ctl is lexicon().

runpath("0:/lib/general.ks").

runpath("0:/lib/launch/rangeControl.ks").
runpath("0:/lib/launch/stagingControl.ks").
runpath("0:/lib/launch/steeringControl.ks").
runpath("0:/lib/launch/throttleControl.ks").

{
   global launch_param is lexicon().

   declare function init_system {
      parameter w.
      parameter b.
      parameter us.
      set launch_param to w.
      
      if exists("0:/launchVehicles/"+b+".ks") {
         runpath("0:/launchVehicles/"+b+".ks").
      }
      if exists("0:/upperStages/"+us+".ks") {
         runpath("0:/upperStages/"+us+".ks").
      }
      launch_ctl["init_range"]().
      launch_ctl["init_staging"](true, true).
      launch_ctl["init_steering"](launch_ctl["launchAzimuth"]()).
      launch_ctl["init_throttle"]().
      
      lock throttle to launch_ctl["throttleProgram"]().
      lock steering to launch_ctl["steeringProgram"]().
   }
   launch_ctl:add("init", init_system@).
}
