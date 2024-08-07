@lazyglobal off.
// Program Template

local programName is "lko-to-moon". //<------- put the name of the script here

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
   kernel_ctl["import-lib"]("lib/maneuver_ctl").
   kernel_ctl["import-lib"]("lib/transfer_ctl").
   
//======== Parameters used by the program ====
   declare parameter argv.
   local engineName is "".
   local targetBody is "".
   if argv:split(" "):length = 2 {
      set engineName to argv:split(" ")[0].
      if not (maneuver_ctl["engineDef"](engineName)) return OP_FAIL.
      set targetBody to argv:split(" ")[1].
      if not (bodyexists(targetBody)) return OP_FAIL.
   } else {
      set kernel_ctl["output"] to
         "Sets up a Hohmann transfer to a body in orbit of the same origin body as the current vessel."
         +char(10)+"Usage: Q lko-to-moon [ENGINE-NAME] [TARGET]".
      return.
   }

//======== Local Variables =====

//=============== Begin program sequence Definition ===============================
   // The actual instructions implementing the program are in delegates, Which the initializer adds to the MISSION_PLAN.
   // In this case, the first part of the program sequence
   // is given as an anonymous function, and the second part is a function implemented in the maneuver_ctl library. 
   // If you do not like anonymous functions, you could implement a named function elsewhere and add a reference
   // to it to the MISSION_PLAN instead, like so: kernel_ctl["MissionPlanAdd"](named_function@).
         kernel_ctl["MissionPlanAdd"](programName, {
            until ship:maxthrust < 1.01*maneuver_ctl["engineStat"](engineName, "thrust") and ship:maxthrust > 0.99*maneuver_ctl["engineStat"](engineName, "thrust") {
               stage. 
            }
            wait 5.
            set target to body(targetBody).
            local mnvr is node(transfer_ctl["etaPhaseAngle"]()+time:seconds, 0,0, transfer_ctl["dv"](ship:body, target)).
            local minimumHeight is 100000.
            if body(targetBody):atm:exists set minimumHeight to body(targetBody):atm:height*1.1.
            else set minimumHeight to body(targetBody):radius*0.1.
            add(mnvr).
            until false {
               if mnvr:orbit:hasnextpatch and mnvr:orbit:nextpatch:body:name = targetBody and mnvr:orbit:nextpatch:periapsis > body(targetBody):radius+minimumHeight {
                  break.
               }else if mnvr:orbit:hasnextpatch and mnvr:orbit:nextpatch:body:name = targetBody and mnvr:orbit:nextpatch:periapsis < body(targetBody):radius+minimumHeight {
                  print "adjusting pe" at(0, 1).
                  set mnvr:prograde to mnvr:prograde + 0.01.
               }else if mnvr:orbit:apoapsis > body(targetBody):altitude {
                  print "adjusting ap" at(0, 1).
                  set mnvr:prograde to mnvr:prograde - 0.01.
               }else {
                  break. 
               }
            }
            maneuver_ctl["add_burn"]("node", engineName, "node", mnvr:deltav:mag).
            return OP_FINISHED.
         }).
         kernel_ctl["MissionPlanAdd"](programName, maneuver_ctl["burn_monitor"]).
//========== End program sequence ===============================
   
}). //End of initializer delegate
