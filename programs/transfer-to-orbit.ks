@lazyglobal off.
// Program Template

local programName is "transfer-to-orbit". //<------- put the name of the script here
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
   if not (defined maneuver_ctl) runpath("0:/lib/maneuver_ctl.ks").
   if not (defined phys_lib) runpath("0:/lib/physics.ks").
   
//======== Parameters used by the program ====
   declare parameter argv.
   local engineName is "".
   local argumentOfPeri is "".
   local newApoapsis is "".
   local newPeriapsis is "".
   if argv:split(" "):length = 4 {
      set engineName to argv:split(" ")[0].
      if not (maneuver_ctl["engineDef"](engineName)) return OP_FAIL.
      set argumentOfPeri to argv:split(" ")[1].
      set newApoapsis to argv:split(" ")[2]:tonumber(ship:apoapsis).
      set newPeriapsis to argv:split(" ")[3]:tonumber(ship:periapsis).
   } else {
      set kernel_ctl["output"] to
         "Attempts to raise the apoapsis to the given altitude, when at the given AOP."
         +char(10)+"Usage: add transfer-to-orbit [ENGINE-NAME] [AOP] [APOAPSIS] [PERIAPSIS]".
      return.
   }

//======== Local Variables =====
      local steerDir is "prograde".

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
      
      if ship:geoposition:lat < -85 {
         local newSMA is (ship:orbit:periapsis+ship:orbit:body:radius*2+newApoapsis)/2.
         local newVatPe is phys_lib["VatAlt"](ship:orbit:body, ship:orbit:periapsis, newSMA).
         local dv is abs(newVatPe - velocityat(ship, eta:periapsis):orbit:mag).
         maneuver_ctl["add_burn"]("prograde", engineName, time:seconds+60, dv, 0.5).
         return OP_FINISHED.
      } else return OP_CONTINUE.
   }).
   kernel_ctl["MissionPlanAdd"](programName, maneuver_ctl["burn_monitor"]).
   //kernel_ctl["MissionPlanAdd"](programName, {
   //   if (steerDir = "prograde" and ship:apoapsis < newAp*0.99 ) or (steerDir = "retrograde" and ship:apoapsis > newAp*1.01) {
   //      if steerDir = "prograde" {
   //         if vang(ship:facing:forevector, ship:prograde:forevector) > 0.5
   //            lock throttle to 0.
   //         wait until vang(ship:facing:forevector, ship:prograde:forevector) < 0.5.
   //      } else {
   //         if vang(ship:facing:forevector, ship:retrograde:forevector) > 0.5
   //            lock throttle to 0.
   //         wait until vang(ship:facing:forevector, ship:retrograde:forevector) < 0.5.
   //      }
   //      lock throttle to 0.1.
   //      return OP_CONTINUE.
   //   } else if (steerDir = "prograde" and ship:apoapsis > newAp*1.01) or (steerDir = "retrograde" and ship:apoapsis < newAp*0.99) {
   //      if steerDir = "prograde" {
   //         set steerDir to "retrograde".
   //      } else {
   //         set steerDir to "prograde".
   //      }
   //      return OP_CONTINUE.
   //   }
   //   return OP_FINISHED.
   //}).
   
         
//========== End program sequence ===============================
   
}). //End of initializer delegate
