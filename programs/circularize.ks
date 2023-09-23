@lazyglobal off.
// Program Template

local programName is "circularize". //<------- put the name of the script here
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
   if not (defined maneuver_ctl) kernel_ctl["import-lib"]("lib/maneuver_ctl").
   
//======== Parameters used by the program ====
   // Don't forget to update the standalone system, above, if you change the number of parameters here.
   declare parameter argv.
   local engineName is "".
   local orbitPoint is "".
   if argv:split(" "):length >= 2 {
      set engineName to argv:split(" ")[0].
      if not (maneuver_ctl["engineDef"](engineName)) return OP_FAIL.
      set orbitPoint to argv:split(" ")[1].
   } else {
      set kernel_ctl["output"] to
         "Executes a maneuver to circularize at the given point."
         +char(10)+"   Usage: Q circularize [ENGINE-NAME] ap | pe".
      return.
   }

//======== Local Variables =====
   local thrustVector is "".
   if orbitPoint:tolower = "ap" set thrustVector to "prograde".
   else if orbitPoint:tolower = "pe" set thrustVector to "retrograde".
   else return OP_FAIL.

//=============== Begin program sequence Definition ===============================
   // The actual instructions implementing the program are in delegates, Which the initializer adds to the MISSION_PLAN.
   // In this case, the first part of the program sequence
   // is given as an anonymous function, and the second part is a function implemented in the maneuver_ctl library. 
   // If you do not like anonymous functions, you could implement a named function elsewhere and add a reference
   // to it to the MISSION_PLAN instead, like so: kernel_ctl["MissionPlanAdd"](named_function@).
   kernel_ctl["MissionPlanAdd"](programName, {
      maneuver_ctl["add_burn"](thrustVector, engineName, orbitPoint:tolower, "circularize").
      return OP_FINISHED.
   }).
   kernel_ctl["MissionPLanAdd"](programName, maneuver_ctl["burn_monitor"]).
//========== End program sequence ===============================
   
}). //End of initializer delegate
