@lazyglobal off.

// Define prelaunch configuration setup for the core here:
// This should theoretically only happen when called by boot/payload.ks
if ship:status = "PRELAUNCH" {
   compile "0:/lib/core/kernel.ks" to "1:/lib/core/kernel.ksm".
   kernel_ctl["load-to-core"]("programs/circularize").
   kernel_ctl["load-to-core"]("lib/core/kernel").

   // Also define a mission_abort routine, to be called, in the case that the booster fails to achieve the specified orbit.
   global mission_abort is {
      kernel_ctl["import-lib"]("programs/circularize").
      kernel_ctl["MissionPlanAdd"]("Continue Ascent", {
         lock throttle to 1.
         lock steering to ship:prograde.
         return OP_FINISHED.
      }).
      kernel_ctl["MissionPlanAdd"]("Achieve Apo", {
         if ship:apoapsis > 300000 {
            lock throttle to 0.
            return OP_FINISHED.
         } else {
            return OP_CONTINUE.
         }
      }).
      kernel_ctl["add"]("circularize", core:tag:split(",")[1]:trim+" ap").  // Define the order of execution, parameter is engine.
      print "Abort routines added to Mission Plan...".
   }.


// boot/payload.ks will compile and swap this in as the new boot file.  So, what follows should, in theory, only ever be executed on subsequent boots.
// Thus, you define the mission firmware below:
} else if ship:status = "SUB_ORBITAL" OR (ship:status = "ORBITING" AND ship:orbit:eccentricity > 0.01 AND eta:apoapsis < ship:orbit:period/2 ) {
   if exists("1:/lib/core/kernel.ksm") { 
      runpath("1:/lib/core/kernel.ksm").
      kernel_ctl["import-lib"]("programs/circularize").
      kernel_ctl["add"]("circularize", core:tag:split(",")[1]:trim+" ap").  // Define the order of execution, parameter is engine.
      kernel_ctl["start"]().                                                        // Execute the mission plan.
   } else {
      print "there has been an error".
      shutdown.
   }
}
