@lazyglobal off.
// Program Template

local programName is "powered-capture". //<------- put the name of the script here

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
   if not (defined maneuver_ctl) runpath("0:/lib/maneuver_ctl.ks").
   
//======== Parameters used by the program ====
   // Don't forget to update the standalone system, above, if you change the number of parameters here.
   declare parameter argv.
   local engineName is "".
   local targetBody is "".
   if argv:split(" "):length = 2 {
      set engineName to argv:split(" ")[0].
      set targetBody to argv:split(" ")[1].
   } else {
      set kernel_ctl["output"] to
         "Sets up a powered capture maneuver, waits until vehicle is inside of the target body's SOI."
         +char(10)+"Usage: add-program powered-capture [ENGINE-NAME] [TARGET]".
      return.
   }

//======== Local Variables =====

//=============== Begin program sequence Definition ===============================
   // The actual instructions implementing the program are in delegates, Which the initializer adds to the MISSION_PLAN.
   // In this case, the first part of the program sequence
   // is given as an anonymous function, and the second part is a function implemented in the maneuver_ctl library. 
   // If you do not like anonymous functions, you could implement a named function elsewhere and add a reference
   // to it to the MISSION_PLAN instead, like so: kernel_ctl["MissionPlanAdd"](named_function@).
   kernel_ctl["MissionPlanAdd"]("wait for soi", {
      set kernel_ctl["status"] to "waiting...".
      if not (ship:orbit:body = body(targetBody)) return OP_CONTINUE.
      set kernel_ctl["status"] to "finished waiting...".
      return OP_FINISHED.
   }).
   kernel_ctl["MissionPlanAdd"]("powered capture", {
      local count is 0.
      until ship:maxthrust < 1.01*maneuver_ctl["engineStat"](engineName, "thrust") and ship:maxthrust > 0.99*maneuver_ctl["engineStat"](engineName, "thrust") {
         print "staging, Max thrust/engineName: "+ship:maxthrust+" "+engineName.
         stage. 
         wait 10.
         if ship:maxthrust = 0 print "Likely a staging problem: Check yo' stagin!".
         if count > 2 {
            return OP_FAIL.
         }
         set count to count +1.
      }
      if ship:orbit:body = body(targetBody) {
         maneuver_ctl["add_burn"]("retrograde", engineName, "pe", "circularize").
      }
      return OP_FINISHED.
   }).
   kernel_ctl["MissionPlanAdd"]("execute maneuver", maneuver_ctl["burn_monitor"]).

//========== End program sequence ===============================
   
}. //End of initializer delegate
