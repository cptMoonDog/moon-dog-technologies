@lazyglobal off.
if ship:status = "PRELAUNCH" {
   wait until not(core:messages:empty). 
   reboot.
}
local nSats is core:tag:split(",")[1]:tonumber(-1).
local procs is list().
list processors in procs.
local foundLVCore is false.
for p in procs {
   if (p:bootfilename = "/boot/lv.ks") {
      set foundLVCore to true.
      break.
   }
}
if nSats = -1 {
   print "Number of satellites being deployed is void.".
   shutdown.
} else if foundLVCore and procs:length > nSats + 1 or not(foundLVCore) and procs:length > nSats {
   // adjust Pe for desired orbit period.
   runpath("0:/lib/core/kernel.ks").
   runpath("0:/lib/physics.ks").

   kernel_ctl["loadProgram"]("change-pe").// why not have this do both? if already loaded, add to mp.
   local nSats is core:tag:split(",")[1]:tonumber(-1).
   if nSats = -1 {
      print "Number of satellites being deployed is void.".
      shutdown.
   }
   local stationPeriod is phys_lib["period"](ship:body, ship:orbit:apoapsis+ship:body:radius).
   local transferPeriod is ((nSats - 1)/nSats)*stationPeriod.
   local transferSMA is phys_lib["sma-from-period"](transferPeriod).
   local newPe is transferSMA - ship:orbit:apoapsis - ship:body:radius*2.
   kernel_ctl["add-program"]("change-pe", newPe).  
   kernel_ctl["start"]().
}

until eta:apoapsis < 365 and eta:apoapsis > 360 {
   local start is eta:apoapsis.
   if start < 360 set start to start + ship:orbit:period.
   if kuniverse:timewarp:rate < 2 {
      kuniverse:timewarp:warpto(time:seconds+start-365).
   }
}
kuniverse:timewarp:cancelwarp.
wait 5.
if procs:length = 1 or (procs:length = 2 and (procs[0]:bootfilename = "/boot/lv.ks" or procs[1]:bootfilename = "/boot/lv.ks")) { // Mother ship will only have one core, or two if mothership has seperate lauch and payload cores.
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
