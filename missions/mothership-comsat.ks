@lazyglobal off.
if ship:status = "PRELAUNCH" {
   wait until not(core:messages:empty). 
   reboot.
} else if ship:status = "SUB_ORBITAL" or ship:orbit:eccentricity > 0.1 {
   // adjust Pe for desired orbit period.
   runpath("0:/lib/core/kernel.ks").
   kernel_ctl["loadProgram"]("change-pe").// why not have this do both? if already loaded, add to mp.
   kernel_ctl["addProgram"]("change-pe").  
   kernel_ctl["start"]().
} else { 
   until eta:apoapsis < 365 and eta:apoapsis > 360 {
      local start is eta:apoapsis.
      if start < 360 set start to start + ship:orbit:period.
      if kuniverse:timewarp:rate < 2 {
         kuniverse:timewarp:warpto(time:seconds+start-365).
      }
   }
   kuniverse:timewarp:cancelwarp.
   wait 5.
   local procs is list().
   list processors in procs.
   if procs:length = 1 or (procs:length = 2 and (procs[0]:bootfilename = "/boot/lv.ks" or procs[1]:bootfilename = "/boot/lv.ks")) { // Mother ship will only have one core, or two if mothership is the upper stage of a launch vehicle.
      // Deorbit the mothership.
      lock steering to ship:retrograde.
      wait 30.
      lock throttle to 1.
      wait until ship:orbit:periapsis < 45000.
      lock throttle to 0.
      shutdown.
   } else {
      lock steering to prograde.
      local stages is procs:length.
      wait 15.
      until procs:length < stages {
         stage.
         wait 1.
         list processors in procs.
      }
      wait 5.
      //kuniverse:switchto().
   }

}