@lazyglobal off.
// Program Template

local programName is "testing". //<------- put the name of the script here

// Header allowing for standalone operation.
//   If this program is to be used as part of a complete mission, run this script without parameters, and
//   then call the functions in the available_programs lexicon in the correct order of events for the mission
//   to build the MISSION_PLAN.
    // If you modify the number of parameters, be sure to fix the function call at the bottom of this file.

if not (defined available_programs) declare global available_programs is lexicon().
if not (defined kernel_ctl) runpath("0:/lib/core/kernel.ks"). 

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
   if not (defined transfer_ctl) runpath("0:/lib/transfer_ctl.ks").
   if not (defined maneuver_ctl) runpath("0:/lib/maneuver_ctl.ks").
   
//======== Parameters used by the program ====
   // Don't forget to update the standalone system, above, if you change the number of parameters here.
   //declare parameter engineName.

//======== Local Variables =====

//=============== Begin program sequence Definition ===============================
   // The actual instructions implementing the program are in delegates, Which the initializer adds to the MISSION_PLAN.
   // In this case, the first part of the program sequence
   // is given as an anonymous function, and the second part is a function implemented in the maneuver_ctl library. 
   // If you do not like anonymous functions, you could implement a named function elsewhere and add a reference
   // to it to the MISSION_PLAN instead, like so: MISSION_PLAN:add(named_function@).
   MISSION_PLAN:add({
      declare function angleToBodyPrograde {
         local bodyVelocity is ship:body:velocity:orbit - ship:body:body:velocity:orbit.
         local velPrograde is ship:velocity:orbit:mag*cos(vang(bodyVelocity, ship:velocity:orbit)).
         //local velPrograde is ((ship:velocity:orbit+bodyVelocity):mag-bodyVelocity:mag).

         local angleToPrograde is (velPrograde/abs(velPrograde))*vang(bodyVelocity, up:forevector).
         if (velPrograde/abs(velPrograde)) < 0 set angleToPrograde to 360 + (velPrograde/abs(velPrograde))*vang(bodyVelocity, up:forevector).
         return angleToPrograde.
      }
      local angleToBodyRetro is angleToBodyPrograde()+180.
      if angleToBodyRetro > 360 set angleToBodyRetro to angleToBodyRetro-360.
      print "prograde: "+angleToBodyPrograde() at(0, 5).
      
      return OP_CONTINUE.
   }).
//========== End program sequence ===============================
   
}. //End of initializer delegate
