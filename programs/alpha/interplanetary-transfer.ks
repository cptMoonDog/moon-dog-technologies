@lazyglobal off.
// Program Template

local programName is "interplanetary-transfer". //<------- put the name of the script here

// Header allowing for standalone operation.
//   If this program is to be used as part of a complete mission, run this script without parameters, and
//   then call the functions in the available_programs lexicon in the correct order of events for the mission
//   to build the MISSION_PLAN.
if not (defined available_programs) declare global available_programs is lexicon().
if not (defined kernel_ctl) runpath("0:/lib/core/kernel.ks"). 
if not (defined phys_lib) runpath("0:/lib/physics.ks"). 
if not (defined maneuver_ctl) runpath("0:/lib/maneuver_ctl.ks").

//Add initialzer for this program sequence to the lexicon of available programs
// Could be written as available_programs:add...but that occasionally produces an error when run as a standalone script.
set available_programs[programName] to {
   //One time initialization code.
   //   Question: Why not simply have a script file with the contents of the initializer delegate?  Why the extra layers?
   //   Answer: It seems that the memory area for parameters passed to scripts is always the same.  So, when 
   //           a script defines a function to be called later, any additional script called with parameters will
   //           clobber the parameter intended for the first one.  The parameter below will be preserved and its value
   //           will remain available to the program, as long as the program is written within this scope, 
  
//======== Imports needed by the program =====
   
//======== Parameters used by the program ====
   // Don't forget to update the standalone system, above, if you change the number of parameters here.
   declare parameter engineName.
   declare parameter targetBody.

//======== Local Variables =====

//=============== Begin program sequence Definition ===============================
   // The actual instructions implementing the program are in delegates, which the initializer adds to the MISSION_PLAN.
   // If you do not like anonymous functions, you could implement a named function elsewhere and add a reference
   // to it to the MISSION_PLAN instead, like so: kernel_ctl["MissionPlanAdd"](named_function@).
   kernel_ctl["MissionPlanAdd"]("interplanetary transfer", {
     /// Hohmann transfer.  Assumes target orbit is coplanar, and circular.
      local secondsToWindow is phys_lib["etaPhaseAngle"](body("Kerbin"), targetBody).
      local orbitsToWindow is secondsToWindow/ship:orbit:period.

      local hohmannTransferVelocity is phys_lib["VatAlt"](body("Sun"),
         ship:body:altitude+body("Sun"):radius,
         phys_lib["sma"](body("Sun"),
         ship:body:altitude+body("Sun"):radius,
         targetBody:altitude+body("Sun"):radius)).

      local etaEjectionAngle is phys_lib["etaEjectionAngle"](hohmannTransferVelocity).
      local dV is phys_lib["ejectionVelocity"](hohmannTransferVelocity)-ship:velocity:orbit:mag.

      if orbitsToWindow > 1 {

         print "Time To Launch Window:" at(0, 3).
         print "seconds: " + secondsToWindow at(0, 4).
         print "minutes: " + secondsToWindow/60 at(0, 5).
         print "hours: " + secondsToWindow/(60*60) at(0, 6).
         print "days: " + secondsToWindow/(60*60*6) at(0, 7).
         print "orbits: " + orbitsToWindow at(0, 8).

         print "etaEjectionAngle: " + etaEjectionAngle at(0, 9).
         print "dV: " + dV at(0, 10).

         set secondsToWindow to phys_lib["etaPhaseAngle"](body("Kerbin"), targetBody).
         set orbitsToWindow to secondsToWindow/ship:orbit:period.
         set etaEjectionAngle to phys_lib["etaEjectionAngle"](hohmannTransferVelocity).
         set dV to phys_lib["ejectionVelocity"](hohmannTransferVelocity)-ship:velocity:orbit:mag.
         if kuniverse:timewarp:warp = 0 and kuniverse:timewarp:rate = 1 and Kuniverse:timewarp:issettled() {
            kuniverse:timewarp:warpto(time:seconds+secondsToWindow-ship:orbit:period).
         }
         if kuniverse:timewarp:mode = "PHYSICS" kuniverse:timewarp:cancelwarp.
         return OP_CONTINUE.
      } else {
         add(node(time:seconds+etaEjectionAngle, 0, 0, dV)).
         return OP_FINISHED.
      }
   }).
   kernel_ctl["MissionPlanAdd"]("add maneuver", {
      if ship:maxthrust > 1.01*maneuver_ctl["engineStat"](engineName, "thrust") {
         stage. 
      }
      maneuver_ctl["add_burn"]("node", engineName, "node", nextnode:deltav:mag).
      return OP_FINISHED.
   }).
   kernel_ctl["MissionPlanAdd"]("execute maneuver", maneuver_ctl["burn_monitor"]).

//========== End program sequence ===============================
   
}. //End of initializer delegate
