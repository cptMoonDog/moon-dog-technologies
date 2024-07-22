@lazyglobal off.

// Initialize 
if ship:status = "PRELAUNCH" { 
   kernel_ctl["load-to-core"]("lib/core/kernel").  
   kernel_ctl["load-to-core"]("lib/physics").  
   kernel_ctl["load-to-core"]("programs/change-apsis").  
} else if core:bootfilename = "/boot/mothership-comsat.ksm" {
   // Only run if directly booted.
   // Start the kernel
   if not (defined kernel_ctl) runpath("1:/lib/core/kernel.ksm").
   // Initialize the system 
   local data is core:tag:split(",").
   local engineName is data[1]:tolower:trim.
   print "engine: "+engineName.
   local nSats is data[2]:tonumber(-1). 
   print "#sats: "+nSats.

   local procs is list().
   list processors in procs.
   local stages is procs:length.
   local deployedSat is 0.
   print "#procs: "+procs:length.
   if nSats = -1 {
      print "Number of satellites being deployed is void.".
      shutdown.
   } else if procs:length > nSats {
   // If deployment has not already started, adjust orbit for correct transfer orbit period.
      kernel_ctl["import-lib"]("lib/physics").
      kernel_ctl["import-lib"]("programs/change-apsis").

      local stationPeriod is phys_lib["period"](ship:body, ship:orbit:apoapsis+ship:body:radius).
      local transferPeriod is ((nSats - 1)/nSats)*stationPeriod.
      local transferSMA is phys_lib["sma-from-period"](ship:body, transferPeriod).
      local newPe is transferSMA*2 - ship:orbit:apoapsis - ship:body:radius*2.
      kernel_ctl["add"]("change-apsis", engineName+" pe "+newPe:tostring).  
   }

   // Warp to near apoapsis
   kernel_ctl["MissionPlanAdd"]("Wait until near apo", {
      // Wait until near apoapsis
      print "waiting til near apo" at(0, 15).
      if eta:apoapsis < 365 and eta:apoapsis > 360 {
         return OP_FINISHED.
      } else {
         local start is eta:apoapsis.
         if start < 360 set start to start + ship:orbit:period.
         if kuniverse:timewarp:rate < 2 {
            kuniverse:timewarp:warpto(time:seconds+start-365).
         }
         return OP_CONTINUE.
      }
   }).
   // Stop warp, and prepare to deploy next satellite
   kernel_ctl["MissionPlanAdd"]("Cancel Warp", {
      print "cancel warp" at(0, 16).
      kuniverse:timewarp:cancelwarp.
      wait 5.
      return OP_FINISHED.
   }).
   if procs:length = 1 { 
      if ship:orbit:periapsis > ship:body:atm:height or (not(ship:body:atm:exists) and  ship:orbit:periapsis > 0) {
         // Deorbit the mothership.
         kernel_ctl["MissionPlanAdd"]("Prep for Deorbit:steering", {
            lock steering to ship:retrograde.
            return OP_FINISHED.
         }).
         kernel_ctl["MissionPlanAdd"]("Prep for Deorbit:throttle", {
            if vang(ship:facing:forevector , ship:retrograde:forevector) < 1 {
               lock throttle to 1.
               return OP_FINISHED.
            } else return OP_CONTINUE.
         }).
         kernel_ctl["MissionPlanAdd"]("Deorbit", {
            if (ship:body:atm:exists and ship:orbit:periapsis < ship:body:atm:height) or ship:orbit:periapsis < 0 {
               lock throttle to 0.
               return OP_FINISHED.
            } else return OP_CONTINUE.
         }).
      }
      kernel_ctl["MissionPlanAdd"]("Stage parachute", {
         if ship:altitude < 3000 AND ship:airspeed < 300 {
            stage.
            wait 1.
            stage.
            wait 1.
            stage.
            shutdown.
            return OP_FINISHED.
         } else {
            return OP_CONTINUE.
         }
      }).
      kernel_ctl["start"]().
   } else {
      // Deploy next satellite
      kernel_ctl["MissionPlanAdd"]("Prep", {
         list processors in procs.
         set stages to procs:length.
         set deployedSat to 0.
         lock steering to prograde.
         return OP_FINISHED.
      }).
      kernel_ctl["MissionPlanAdd"]("Stage",{
         wait 0.
         list processors in procs.
         if procs:length = stages {
            stage.
            // One of these won't be on this ship any more. :)
            for p in procs {
               print p:part:ship:name.
               if not(p:part:ship = ship) {
                  set deployedSat to p:part:ship.
                  print deployedSat:name.
               }
            }
            return OP_CONTINUE.
         } else {
            // One of these won't be on this ship any more. :
            for p in procs {
               if not(p:part:ship = ship) {
                  print p:part:ship:name.
                  set deployedSat to p:part:ship.
                  print deployedSat:name.
               }
            }
            if deployedSat = 0 {
               set kernel_ctl["status"] to "Waiting for deployment".
               return OP_CONTINUE.
            } else {
               set kuniverse:activevessel to deployedSat.
               return OP_FINISHED.
            }
         }
      }).
      kernel_ctl["MissionPlanAdd"]("Wait for switch", {
         if kuniverse:activevessel = ship  return OP_CONTINUE.
         else return OP_FINISHED.
      }).
      kernel_ctl["MissionPlanAdd"]("Wait for return", {
         if kuniverse:activevessel = ship  {
            reboot.
            return OP_FINISHED.
         } else return OP_CONTINUE.
      }).
      kernel_ctl["start"]().
   }

}
