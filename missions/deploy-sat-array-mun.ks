@lazyglobal off.

// Define prelaunch configuration setup for the core here:
// This should theoretically only happen when called by boot/payload.ks
if ship:status = "PRELAUNCH" {
   compile "0:/lib/core/kernel.ks" to "1:/lib/core/kernel.ksm".
   kernel_ctl["load-to-core"]("lib/core/kernel").
   kernel_ctl["load-to-core"]("lib/maneuver_ctl").
   kernel_ctl["load-to-core"]("lib/transfer_ctl").
   kernel_ctl["load-to-core"]("programs/lko-to-moon").
   kernel_ctl["load-to-core"]("programs/powered-capture").
   kernel_ctl["load-to-core"]("programs/match-plane").
   kernel_ctl["load-to-core"]("programs/change-apsis").

   compile "0:/missions/mothership-comsat.ks" to "1:/boot/mothership-comsat.ksm".
   runpath("1:/boot/mothership-comsat.ksm").

   // Also define a mission_abort routine, to be called, in the case that the booster fails to achieve the specified orbit.
   global mission_abort is {
      print "Abort routines added to Mission Plan...".
   }.

// boot/payload.ks will compile and swap this in as the new boot file.  So, what follows should, in theory, only ever be executed on subsequent boots.
// Thus, you define the mission firmware below:
} else if ship:status = "SUB_ORBITAL" OR (ship:status = "ORBITING" AND ship:orbit:eccentricity < 0.01) {
   if exists("1:/lib/core/kernel.ksm") { 
      runpath("1:/lib/core/kernel.ksm").
      kernel_ctl["import-lib"]("programs/lko-to-moon").
      kernel_ctl["import-lib"]("programs/warp-to-soi").
      kernel_ctl["import-lib"]("programs/powered-capture").
      kernel_ctl["import-lib"]("programs/match-plane").
      kernel_ctl["import-lib"]("programs/change-apsis").
      
      kernel_ctl["add"]("lko-to-moon", "terrier Mun").
      kernel_ctl["add"]("warp-to-soi", "Mun").
      kernel_ctl["add"]("powered-capture", "terrier Mun").
      kernel_ctl["add"]("match-plane", "terrier 90:135").
      kernel_ctl["add"]("change-apsis", "terrier ap 592500").
      kernel_ctl["MissionPlanAdd"]("Change bootfile to next mission", {
         set core:tag to "Munflower, terrier, 4".
         set core:bootfilename to "/boot/mothership-comsat.ksm".
         reboot.
         return OP_FINISHED.
      }).
      
      kernel_ctl["start"]().                                                        // Execute the mission plan.
      shutdown.
   } else {
      print "there has been an error".
      shutdown.
   }
   print "Mun-orbit-script finished in orbit mode".
   shutdown.
}
print "Mun-orbit-script completed".
