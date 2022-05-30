@lazyglobal off.
// Program Template

local programName is "rendezvous". //<------- put the name of the script here

// Header allowing for standalone operation.
//   If this program is to be used as part of a complete mission, run this script without parameters, and
//   then call the functions in the available_programs lexicon in the correct order of events for the mission
//   to build the MISSION_PLAN.
    // If you modify the number of parameters, be sure to fix the function call at the bottom of this file.

if not (defined kernel_ctl) runpath("0:/lib/core/kernel.ks"). 

//Add initialzer for this program sequence to the lexicon of available programs
// Could be written as available_programs:add...but that occasionally produces an error when run as a standalone script.
kernel_ctl["availablePrograms"]:add(programName, {
   //One time initialization code.
   //   Question: Why not simply have a script file with the contents of the initializer delegate?  Why the extra layers?
   //   Answer: It seems that the memory area for parameters passed to scripts is always the same.  So, when 
   //           a script defines a function to be called later, any additional script called with parameters will
   //           clobber the parameter intended for the first one.  The parameter below will be preserved and its value
   //           will remain available to the program, as long as the program is written within this scope, 
  
//======== Imports needed by the program =====
   if not (defined transfer_ctl) runpath("0:/lib/transfer_ctl.ks").
   if not (defined maneuver_ctl) runpath("0:/lib/maneuver_ctl.ks").
   
//======== Parameters used by the program ====
   // Don't forget to update the standalone system, above, if you change the number of parameters here.
   declare parameter argv.
   local engineName is "".
   local targetObject is "".
   if argv:split(" "):length > 1 {
      set engineName to argv:split(" ")[0].
      if not (maneuver_ctl["engineDef"](engineName)) return OP_FAIL.
      if argv:split(char(34)):length > 1 set targetObject to argv:split(char(34))[1]. // Quoted second parameter
      else set targetObject to argv:split(" ")[1].
      set kernel_ctl["output"] to "target: "+ targetObject.
   } else {
      set kernel_ctl["output"] to
         "Creates a rendezvous with a ship or object in a coplanar orbit."
         +char(10)+"Usage: add-program rendezvous [ENGINE-NAME] [TARGET]".
      return.
   }

//======== Local Variables =====

//=============== Begin program sequence Definition ===============================
   // The actual instructions implementing the program are in delegates, Which the initializer adds to the MISSION_PLAN.
   // In this case, the first part of the program sequence
   // is given as an anonymous function, and the second part is a function implemented in the maneuver_ctl library. 
   // If you do not like anonymous functions, you could implement a named function elsewhere and add a reference
   // to it to the MISSION_PLAN instead, like so: kernel_ctl["MissionPlanAdd"](named_function@).

   
      kernel_ctl["MissionPLanAdd"](programName, {
         set target to targetObject.
         if not hastarget return OP_FAIL.
         // Originally made with targets in higher orbits in mind.
         if target:orbit:apoapsis < 1.01*ship:orbit:apoapsis and target:orbit:apoapsis > 0.99*ship:orbit:apoapsis return OP_FINISHED. // 
         if not (hasnode) {
            local mnvr is node(transfer_ctl["etaPhaseAngle"]()+time:seconds, 0,0, transfer_ctl["dv"](ship:body, target)).
            add(mnvr).
            maneuver_ctl["add_burn"]("node", engineName, "node", mnvr:deltav:mag).
            return OP_FINISHED.
         }
         print "Maneuver creation failed.".
         return OP_FAIL.
      }).
      kernel_ctl["MissionPLanAdd"](programName, maneuver_ctl["burn_monitor"]).
      kernel_ctl["MissionPLanAdd"](programName, {
         local dist is {return (positionat(target, time:seconds)-positionat(ship, time:seconds)).}.
         local relVelocity is {return (ship:velocity:orbit - target:velocity:orbit).}.
         local velToward is {return relVelocity():mag*cos(vang(relVelocity(), dist())).}.  //speed toward target
         print "toward: "+velToward() at(0, 5).
         print "RelVelocity: "+relVelocity():mag at(0, 6).
         lock steering to -1*relVelocity().
         if dist():mag > 5000 return OP_CONTINUE.
         if dist():mag < 150 { // Within relativistic frame
            if relVelocity():mag < 1 {
               lock throttle to 0.
               lock steeering to ship:prograde.
               return OP_FINISHED.
            } else if relVelocity():mag > 1 {
               lock steering to -1*relVelocity().
               // Below: Wait until ship is pointed at retrograde in reference to target.
               if vang(-1*(ship:velocity:orbit - target:velocity:orbit), ship:facing:forevector) > 1 {return OP_CONTINUE.}
               lock throttle to abs(relVelocity():mag)/100.
            }
         } else { // Not close enough
            if velToward() < -0.5 { // drifting away
               if vang(-1*relVelocity(), ship:facing:forevector) > 1 {return OP_CONTINUE.}
               lock throttle to abs(relVelocity():mag)/100.
               if abs(relVelocity():mag) > 1 {return OP_CONTINUE.}
               lock throttle to 0.
            } else if abs(velToward()) < 5 and relVelocity():mag < 6 { // Need to move a little faster
               lock steering to dist().  // Point at target
               if vang(dist(), ship:facing:forevector) > 1 {return OP_CONTINUE.}
               lock throttle to 0.1.
               if abs((ship:velocity:orbit - target:velocity:orbit):mag) < dist():mag/180 {return OP_CONTINUE.}
               lock throttle to 0.
            }
         }
         return OP_CONTINUE.
      }).
         
         
         
//========== End program sequence ===============================
   
}). //End of initializer delegate
