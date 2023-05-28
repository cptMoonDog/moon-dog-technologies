@lazyglobal off.

// This is for a deployable communications satellite
local procs is list().
list processors in procs.
if ship:status = "PRELAUNCH" {
   // Configure core for flight.
   compile "0:/lib/core/kernel.ks" to "1:/lib/core/kernel.ksm".
   kernel_ctl["load-to-core"]("lib/physics").
   kernel_ctl["load-to-core"]("lib/maneuver_ctl").
   kernel_ctl["load-to-core"]("programs/circularize-at-ap").
   kernel_ctl["load-to-core"]("programs/orient-to-max-solar").
   //kernel_ctl["load-to-core"]("program/station-keep-behind").
   global mission_abort is {}.
} else  if ((ship:status = "ORBITING" OR ship:status = "FLYING" OR ship:status = "SUB_ORBITAL") and procs:length > 1) {
   clearscreen.
   // Still waiting to be deployed.
   print "orbiting".
   // Finalize orbit after separation.
   local mothership is ship.
   print "Mothership: "+mothership:name.
   until procs:length = 1 {
      list processors in procs.
      wait 1.
   }
   wait 1.
   print core:tag.
   set ship:name to core:tag:split(":")[0].
   print "my name: "+ship:name.
   print "my engine: "+core:tag:split(",")[1]:trim.
   runpath("1:/lib/core/kernel.ksm").                                // Startup the system
   print "kernel started".
   kernel_ctl["import-lib"]("programs/circularize-at-ap").                    // Make pre-defined programs available
   kernel_ctl["add-program"]("circularize-at-ap", core:tag:split(",")[1]:trim).                   // Define the order of execution, parameter is engine.
   print "MP initialized".
   kernel_ctl["start"]().                                            // Execute the mission plan.
   print "MP completed".
   wait 5.
   set kuniverse:activevessel to mothership.
   wait 0.
} else if ship:status = "ORBITING" and procs:length = 1{ // On station.
   runpath("1:/lib/core/kernel.ksm").                                // Startup the system
   kernel_ctl["import-lib"]("programs/orient-to-max-solar").                    // Make pre-defined programs available
   //kernel_ctl["import-lib"]("station-keep-behind").                    // Make pre-defined programs available

   //available_programs["station-keep-behind"](core:tag:split(",")[1], core:tag:split(",")[2]). // Engine, target
   kernel_ctl["availablePrograms"]["orient-to-max-solar"]("").                   // Define the order of execution.

   kernel_ctl["start"]().
}
print "Bootfile completed".
