@lazyglobal off.
/// This library's list of  exported functions.
if not (defined launch_ctl)
   global launch_ctl is lexicon().

runoncepath("0:/lib/physics.ks").
runoncepath("0:/lib/maneuver_ctl.ks").

runoncepath("0:/lib/launch/range_ctl.ks").
runoncepath("0:/lib/launch/staging_ctl.ks").
runoncepath("0:/lib/launch/steering_ctl.ks").
runoncepath("0:/lib/launch/throttle_ctl.ks").

{
   global launch_param is lexicon().

   declare function init_system {
      launch_ctl["init_range"]().
      launch_ctl["init_staging"]().
      launch_ctl["init_steering"](launch_ctl["launchAzimuth"]()).
      launch_ctl["init_throttle"]().
   }
   launch_ctl:add("init", init_system@).
   
   // This function requires that the kernel has already been initialized.
   declare function setupLaunch {   
      kernel_ctl["MissionPlanAdd"]("init", {
         launch_ctl["init_range"](). // ISH delays launch, and was preventing countdown, so run this again.
         return OP_FINISHED.
      }).
      kernel_ctl["MissionPlanAdd"]("countdown", launch_ctl["countdown"]).
      kernel_ctl["MissionPlanAdd"]("launch", launch_ctl["launch"]).
      kernel_ctl["MissionPlanAdd"]("ascent", {
         set kernel_ctl["status"] to "Ascent".
        //Calls staging check, and throttle defines end of this mode.
        launch_ctl["staging"]().
        if ship:verticalspeed < -100 {
           set kernel_ctl["status"] to "WARNING! Failed to achieve orbit!".
           local procs is list().
           list processors in procs.
           for payloadCore in procs {
                 payloadCore:connection:sendmessage("ABORT").
           }
           return OP_FAIL.
        }
        return launch_ctl["throttle_monitor"]().
      }, {
         lock throttle to 0.
         stage.
         wait 1.
         stage.
         wait 1.
         stage.
         return OP_FINISHED.
      }).
      if not (launch_param:haskey("orbitType")) or not(launch_param["orbitType"] = "transfer") {
         kernel_ctl["MissionPlanAdd"]("circularize", {
            set kernel_ctl["status"] to "Setup circularization...".
            //If the upperstage is not the active engine...
            if ship:maxthrust > 1.01*maneuver_ctl["engineStat"](launch_param["upperstage"], "thrust") { //Maxthrust is float, straight comparison sometimes fails. 
               stage. 
            }
            maneuver_ctl["add_burn"]("prograde", launch_param["upperstage"], "ap", "circularize").
            if maneuver_ctl["getStartTime"]() < time:seconds and ship:periapsis < ship:body:atm:height {
               maneuver_ctl["abort_burn"]().
               lock steering to ship:prograde.
               lock throttle to 1. // Try to recover 
               return OP_CONTINUE.
            } else {
               lock steering to ship:prograde.
               lock throttle to 0.
            }
            return OP_FINISHED.
         }).
         kernel_ctl["MissionPlanAdd"]("execute maneuver", maneuver_ctl["burn_monitor"]).
      }
   }
   launch_ctl:add("addLaunchToMissionPlan", setupLaunch@).
}
