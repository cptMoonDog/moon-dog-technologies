@lazyglobal off.

// Define prelaunch configuration setup for the core here:
// This should theoretically only happen when called by boot/payload.ks
if ship:status = "PRELAUNCH" {
   compile "0:/lib/core/kernel.ks" to "1:/lib/core/kernel.ksm".
   kernel_ctl["load-to-core"]("lib/core/kernel.ks").

   // Also define a mission_abort routine, to be called, in the case that the booster fails to achieve the specified orbit.
   global mission_abort is {
      print "Abort routines added to Mission Plan...".
   }.


// boot/payload.ks will compile and swap this in as the new boot file.  So, what follows should, in theory, only ever be executed on subsequent boots.
// Thus, you define the mission firmware below:
} else if ship:status = "SUB_ORBITAL" OR (ship:status = "ORBITING" AND ship:orbit:eccentricity > 0.01 AND eta:apoapsis < ship:orbit:period/2 ) {
   if exists("1:/lib/core/kernel.ksm") { 
      runpath("1:/lib/core/kernel.ksm").
      kernel_ctl["start"]().                                                        // Execute the mission plan.
   } else {
      print "there has been an error".
      shutdown.
   }
}
