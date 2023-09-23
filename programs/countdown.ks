@lazyglobal off.
// Program Template

local programName is "countdown". //<------- put the name of the script here

//Add initialzer for this program sequence to the lexicon of available programs
// Could be written as available_programs:add...but that occasionally produces an error when run as a standalone script.
kernel_ctl["availablePrograms"]:add(programName, {

//======== Imports needed by the program =====
   
//======== Parameters used by the program ====
   declare parameter argv.
   local timeLength is "".
   if argv:trim {
      set kernel_ctl["output"] to argv.
      set timeLength to argv:tonumber(-1).
      if timeLength = -1 {
         set kernel_ctl["output"] to
            "Adds a simple countdown to the MissonPlan. Defaults to 10 seconds."
            +char(10)+"Usage: Q countdown [LENGTH SECONDS (Optional)]".
         return.
      }
   } else {
      set timeLength to 10.
   }

//======== Local Variables =====
   local starttime is 0.

//=============== Begin program sequence Definition ===============================
      kernel_ctl["MissionPlanAdd"](programName, {
         set starttime to time:seconds.
         return OP_FINISHED.
      }).
      kernel_ctl["MissionPlanAdd"](programName, {
         if time:seconds < starttime + timeLength {
            set kernel_ctl["countdown"] to "T-"+ceiling(starttime + timeLength - time:seconds):tostring.
            return OP_CONTINUE.
         } else {
            set kernel_ctl["countdown"] to "T-0".
            return OP_FINISHED.
         }
      }).
         
//========== End program sequence ===============================
   
}). //End of initializer delegate
