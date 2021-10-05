@lazyglobal off.
// Program Template

local programName is "lko-to-moon". //<------- put the name of the script here

// Header allowing for standalone operation.
//   If this program is to be used as part of a complete mission, run this script without parameters, and
//   then call the functions in the available_programs lexicon in the correct order of events for the mission
//   to build the MISSION_PLAN.
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
   declare parameter engineName.
   declare parameter targetBody.

//======== Local Variables =====

//=============== Begin program sequence Definition ===============================
   // The actual instructions implementing the program are in delegates, Which the initializer adds to the MISSION_PLAN.
   // In this case, the first part of the program sequence
   // is given as an anonymous function, and the second part is a function implemented in the maneuver_ctl library. 
   // If you do not like anonymous functions, you could implement a named function elsewhere and add a reference
   // to it to the MISSION_PLAN instead, like so: MISSION_PLAN:add(named_function@).
         MISSION_PLAN:add({
            until ship:maxthrust < 1.01*maneuver_ctl["engineStat"](engineName, "thrust") and ship:maxthrust > 0.99*maneuver_ctl["engineStat"](engineName, "thrust") {
               stage. 
            }
            wait 5.
            set target to body(targetBody).
            local mnvr is node(transfer_ctl["etaPhaseAngle"]()+time:seconds, 0,0, transfer_ctl["dv"](ship:body, target)).
            add(mnvr).
            until false {
               if mnvr:orbit:hasnextpatch and mnvr:orbit:nextpatch:body:name = targetBody and mnvr:orbit:nextpatch:periapsis > body(targetBody):radius+10000 {
                  break.
               }else if mnvr:orbit:hasnextpatch and mnvr:orbit:nextpatch:body:name = targetBody and mnvr:orbit:nextpatch:periapsis < body(targetBody):radius+10000 {
                  print "adjusting pe" at(0, 1).
                  set mnvr:prograde to mnvr:prograde + 0.01.
               }else if mnvr:orbit:apoapsis > body("Mun"):altitude {
                  print "adjusting ap" at(0, 1).
                  set mnvr:prograde to mnvr:prograde - 0.01.
               }else {
                  break. 
               }
            }
            maneuver_ctl["add_burn"]("node", engineName, "node", mnvr:deltav:mag).
            return OP_FINISHED.
         }).
         MISSION_PLAN:add(maneuver_ctl["burn_monitor"]).
//========== End program sequence ===============================
   
}. //End of initializer delegate
