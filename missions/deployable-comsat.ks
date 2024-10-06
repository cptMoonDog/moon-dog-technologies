//How to use
// Place the satellite on the stack, and use the payload.ks bootfile
// Set the core:tag value to: [Satellite Name]:deployable-comsat, [ENGINE], [Circularization point ap | pe (optional, default: ap)]
@lazyglobal off.

// This is for a deployable communications satellite
local procs is list().
list processors in procs.
if ship:status = "PRELAUNCH" {
   // Configure core for flight.
   local parameters is core:tag.
   local elpType is parameters:contains("elp"). // Elliptical deployment type
   compile "0:/lib/core/kernel.ks" to "1:/lib/core/kernel.ksm".
   kernel_ctl["load-to-core"]("lib/physics").
   kernel_ctl["load-to-core"]("lib/maneuver_ctl").
   if elpType {
      kernel_ctl["load-to-core"]("programes/run-maneuver").
   } else kernel_ctl["load-to-core"]("programs/circularize").
   kernel_ctl["load-to-core"]("programs/orient-to-max-solar").
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
   local elpType is core:tag:contains("elp").
   set ship:name to core:tag:split(":")[0].
   local myEngine is core:tag:split(",")[1]:trim.
   print "my name: "+ship:name.
   print "my engine: "+myEngine.
   runpath("1:/lib/core/kernel.ksm").                                // Startup the system
   print "kernel started".
   if elpType {
      kernel_ctl["import-lib"]("lib/physics").
      kernel_ctl["import-lib"]("lib/maneuver_ctl").
      local deployAngle is core:tag:split(",")[3]:trim:tonumber(90).
      local dv is (phys_lib["VatAlt"](ship:orbit:body, ship:altitude, phys_lib["sma"](ship:orbit:body, ship:altitude, ship:body:soiradius*0.99))-ship:velocity:orbit:mag).
      kernel_ctl["MissionPlanAdd"]("Add Burn", {
         maneuver_ctl["add_burn"]("prograde", myEngine, time:seconds+phys_lib["etaAnglePastANDN"]("AN", deployAngle), dv).
         return OP_FINISHED.
      }).
      kernel_ctl["MissionPlanAdd"]("Burn Monitor", maneuver_ctl["burn_monitor"]).
   } else {
      kernel_ctl["import-lib"]("programs/circularize").                    // Make pre-defined programs available
      local circPoint is choose core:tag:split(",")[2]:trim if core:tag:split(","):length = 3 else "ap". 
      kernel_ctl["add"]("circularize", core:tag:split(",")[1]:trim+" "+circPoint).                   
   }
   print "MP initialized".
   kernel_ctl["start"]().                                            // Execute the mission plan.
   print "MP completed".
   panels on.
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
