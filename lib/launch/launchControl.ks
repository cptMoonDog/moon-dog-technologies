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
runpath("0:/lib/core/kernel.ks").

{
   global launch_param is lexicon().

   declare function init_system {
      parameter w.
      parameter booster. //Booster
      parameter upperStage. //Upper Stage
      set launch_param to w.
      
      if exists("0:/launchVehicles/"+booster+".ks") {
         runpath("0:/launchVehicles/"+booster+".ks").
      }
      if upperStage and exists("0:/upperStages/"+upperStage+".ks") {
         runpath("0:/upperStages/"+upperStage+".ks").
      }
      launch_ctl["init_range"]().
      launch_ctl["init_staging"](true, true).
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
        return launch_ctl["throttle_monitor"]().
      }).
      MISSION_PLAN:add({
         maneuver_ctl["add_burn"](launch_ctl["steeringProgram"], launch_param["US_isp"], launch_param["US_FF"], "ap", "circularize").
         return OP_FINISHED.
      }).
      MISSION_PLAN:add(maneuver_ctl["burn_monitor"]).
   }
   launch_ctl:add("addLaunchToMissionPlan", setupLaunchToLKO@).
}
