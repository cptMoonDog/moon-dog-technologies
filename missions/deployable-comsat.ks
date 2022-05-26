@lazyglobal off.

// This is for a deployable communications satellite
local procs is list().
list processors in procs.
if ship:status = "PRELAUNCH" { //and not(exists("1:/lib/core/kernel.ksm")) {
   // Configure core for flight.
   compile "0:/lib/core/kernel.ks" to "1:/lib/core/kernel.ksm".
   runpath("1:/lib/core/kernel.ksm").
   kernel_ctl["load-to-core"]("lib/physics").
   kernel_ctl["load-to-core"]("lib/maneuver_ctl").
   kernel_ctl["load-to-core"]("programs/circularize-at-ap").
   kernel_ctl["load-to-core"]("programs/orient-to-max-solar").
   //kernel_ctl["load-to-core"]("program/station-keep-behind").
   wait until ship:status = "ORBITING".
   reboot.
} else  if ship:status = "ORBITING" and procs:length > 1 {
   // Finalize orbit after seperation.
   local mothership is ship:name.
   until procs:length = 1 {
      list processors in procs.
      wait 0.
   }
   set ship:name to core:tag:split(",")[0].
   runpath("1:/lib/core/kernel.ksm").                                // Startup the system
   kernel_ctl["import-lib"]("circularize-at-ap").                    // Make pre-defined programs available

   kernel_ctl["add-program"]("circularize-at-ap", core:tag:split(",")[1]).                   // Define the order of execution, parameter is engine.
   kernel_ctl["MissionPlanAdd"]({ // Send player back to mothership.
      set kuniverse:activevessel to vessel(mothership).
   }).

   kernel_ctl["start"]().                                            // Execute the mission plan.
} else if ship:status = "ORBITING" and procs:length = 1{ // On station.
   runpath("1:/lib/core/kernel.ksm").                                // Startup the system
   kernel_ctl["import-lib"]("orient-to-max-solar").                    // Make pre-defined programs available
   //kernel_ctl["import-lib"]("station-keep-behind").                    // Make pre-defined programs available

   //available_programs["station-keep-behind"](core:tag:split(",")[1], core:tag:split(",")[2]). // Engine, target
   available_programs["orient-to-max-solar"]().                   // Define the order of execution.

   kernel_ctl["start"]().
}
   