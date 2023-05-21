@lazyglobal off.

if ship:status = "PRELAUNCH" {
   compile "0:/lib/core/kernel.ks" to "1:/lib/core/kernel.ksm".
   kernel_ctl["load-to-core"]("programs/circularize-at-ap").
   kernel_ctl["load-to-core"]("lib/core/kernel.ks").
   global mission_abort is {
      kernel_ctl["import-lib"]("programs/circularize-at-ap").
      kernel_ctl["MissionPlanAdd"]("Continue Ascent", {
         lock throttle to 1.
         lock steering to ship:prograde.
         return OP_FINISHED.
      }).
      kernel_ctl["MissionPlanAdd"]("Achieve Apo", {
         if ship:apoapsis > 250000 {
            lock throttle to 0.
            return OP_FINISHED.
         } else {
            return OP_CONTINUE.
         }
      }).
      kernel_ctl["add-program"]("circularize-at-ap", core:tag:split(",")[1]:trim).  // Define the order of execution, parameter is engine.
      print "Abort routines added to Mission Plan...".
   }.
} else if ship:status = "SUB_ORBITAL" OR (ship:status = "ORBITING" AND ship:orbit:eccentricity > 0.01 AND eta:apoapsis < ship:orbit:period/2 ) {
   if exists("1:/lib/core/kernel.ksm") { 
      runpath("1:/lib/core/kernel.ksm").
      kernel_ctl["import-lib"]("programs/circularize-at-ap").
      kernel_ctl["add-program"]("circularize-at-ap", core:tag:split(",")[1]:trim).  // Define the order of execution, parameter is engine.
      kernel_ctl["start"]().                                                        // Execute the mission plan.
   } else {
      print "there has been an error".
      shutdown.
   }
}
