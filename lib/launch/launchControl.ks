@lazyglobal off.
/// This library's list of  exported functions.
if not (defined launch_ctl)
   global launch_ctl is lexicon().

runpath("0:/lib/general.ks").

runpath("0:/lib/launch/rangeControl.ks").
runpath("0:/lib/launch/stagingControl.ks").
runpath("0:/lib/launch/steeringControl.ks").
runpath("0:/lib/launch/throttleControl.ks").

runpath("0:/lib/maneuverControl.ks").
runpath("0:/engine-conf.ks").
runpath("0:/lib/core/kernel.ks").

{
   global launch_param is lexicon().

   declare function init_system {
      parameter hasFairing.
      parameter ag1.
      
      launch_ctl["init_range"]().
      launch_ctl["init_staging"](hasFairing, ag1).
      launch_ctl["init_steering"](launch_ctl["launchAzimuth"]()).
      launch_ctl["init_throttle"]().
   }
   launch_ctl:add("init", init_system@).
   
   declare function setupLaunchToLKO {   
      MISSION_PLAN:add(launch_ctl["countdown"]).
      MISSION_PLAN:add(launch_ctl["launch"]).
      MISSION_PLAN:add({
        //Calls staging check, and throttle defines end of this mode.
        launch_ctl["staging"]().
        if ship:verticalspeed < -100 {
           print "WARNING! Failed to achieve orbit!".
           return OP_FAIL.
        }
        return launch_ctl["throttle_monitor"]().
      }).
      MISSION_PLAN:add({
         if ship:maxthrust > 1.01*engineStat(launch_param["upperstage"], "thrust") { //Maxthrust is float, straight comparison sometimes fails. 
            print "maxthrust: "+ship:maxthrust at(0, 21).
            stage. 
         }
         maneuver_ctl["add_burn"](launch_ctl["steeringProgram"], launch_param["upperstage"], "ap", "circularize").
         return OP_FINISHED.
      }).
      MISSION_PLAN:add(maneuver_ctl["burn_monitor"]).
   }
   launch_ctl:add("addLaunchToMissionPlan", setupLaunchToLKO@).
}
