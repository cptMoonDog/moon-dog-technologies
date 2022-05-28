@lazyglobal off.
//if ship:status = "PRELAUNCH" {
//   wait until not(core:messages:empty). 
//   reboot.
//}

local data is core:tag:split(",").
print "data: "+data.
local engineName is data[1]:tolower:trim.
print "engine: "+engineName.
local nSats is data[2]:tonumber(-1). 
print "#sats: "+nSats.

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
   kernel_ctl["import-lib"]("lib/physics").

   kernel_ctl["import-lib"]("programs/change-pe").

   local stationPeriod is phys_lib["period"](ship:body, ship:orbit:apoapsis+ship:body:radius).
   local transferPeriod is ((nSats - 1)/nSats)*stationPeriod.
   local transferSMA is phys_lib["sma-from-period"](ship:body, transferPeriod).
   local newPe is transferSMA*2 - ship:orbit:apoapsis - ship:body:radius*2.
   kernel_ctl["add-program"]("change-pe", engineName+" "+newPe:tostring).  

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
   local deployedSat is 0.
   until procs:length < stages {
      stage.
      wait 5.
      for p in procs {
         if not(p:part:ship = ship) {
            print p:part:ship:name.
            //set kuniverse:activevessel to p:part:ship.
            set deployedSat to p:part:ship.
            wait 2.
            print deployedSat:name.
            break.
         }
         wait 0.
      }
      if not(deployedSat = 0) break.
      //list processors in procs.
      wait 0.
   }
   wait 5.
   set kuniverse:activevessel to deployedSat.
}

wait until kuniverse:activevessel = ship.
reboot.