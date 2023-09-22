@lazyglobal off.
// Program Template

local programName is "warp-to-soi". //<------- put the name of the script here
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
   
//======== Parameters used by the program ====
   // Don't forget to update the standalone system, above, if you change the number of parameters here.
   declare parameter targetBody.
   if argv:split(" "):length >= 1 {
      set targetBody to argv:split(" ")[0].
   } else {
      set kernel_ctl["output"] to
         "Initiates warp until the next encounter with [TARGET BODY]"
         +char(10)+"   Usage: add warp-to-soi [TARGET BODY]".
      return.
   }
//======== Local Variables =====

//=============== Begin program sequence Definition ===============================
   // The actual instructions implementing the program are in delegates, which the initializer adds to the MISSION_PLAN.
   // If you do not like anonymous functions, you could implement a named function elsewhere and add a reference
   // to it to the MISSION_PLAN instead, like so: kernel_ctl["MissionPlanAdd"](named_function@).
   kernel_ctl["MissionPLanAdd"](programName,{
      if ship:orbit:hasnextpatch and ship:orbit:nextpatch:body = body(targetBody) {
         if kuniverse:timewarp:warp = 0 and kuniverse:timewarp:rate = 1 and Kuniverse:timewarp:issettled() and ship:orbit:nextpatcheta > 180 {
            warpto(ship:orbit:nextpatcheta+time:seconds-180).
         }
         if kuniverse:timewarp:mode = "PHYSICS" kuniverse:timewarp:cancelwarp.
         return OP_CONTINUE.
      }
      return OP_FINISHED.
   }).

//========== End program sequence ===============================
   
}). //End of initializer delegate
