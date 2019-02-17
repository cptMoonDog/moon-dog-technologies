@lazyglobal off.
/// This library's list of  exported functions.
if not (defined launch_ctl)
   global launch_ctl is lexicon().

runpath("0:/lib/physics.ks").

runpath("0:/lib/launch/range_ctl.ks").
runpath("0:/lib/launch/staging_ctl.ks").
runpath("0:/lib/launch/steering_ctl.ks").
runpath("0:/lib/launch/throttle_ctl.ks").

runpath("0:/lib/maneuver_ctl.ks").
runpath("0:/lib/core/kernel.ks").

{
   global launch_param is lexicon().

   declare function init_system {
      launch_ctl["init_range"]().
      launch_ctl["init_staging"]().
      launch_ctl["init_steering"](launch_ctl["launchAzimuth"]()).
      launch_ctl["init_throttle"]().
      if launch_param:haskey("show telemetry") and launch_param["show telemetry"] = "true" {
         print "showing telemetry" at(0, 2).
         runpath("0:/lib/core/telemetry.ks").
         INTERRUPTS:add(telemetry_ctl["display"]).
      }
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
         //If the upperstage is not the active engine...
         if ship:maxthrust > 1.01*maneuver_ctl["engineStat"](launch_param["upperstage"], "thrust") { //Maxthrust is float, straight comparison sometimes fails. 
            stage. 
         }
         maneuver_ctl["add_burn"]("prograde", launch_param["upperstage"], "ap", "circularize").
         if maneuver_ctl["getStartTime"]() < time:seconds and ship:periapsis < ship:body:atm:height lock throttle to 1.
         else {
            lock steering to ship:prograde.
            lock throttle to 0.
         }
         return OP_FINISHED.
      }).
      MISSION_PLAN:add(maneuver_ctl["burn_monitor"]).
   }
   launch_ctl:add("addLaunchToMissionPlan", setupLaunchToLKO@).
}
