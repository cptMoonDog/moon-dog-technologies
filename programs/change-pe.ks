@lazyglobal off.
// Program Template

local programName is "change-pe". //<------- put the name of the script here

// Header allowing for standalone operation.
//   If this program is to be used as part of a complete mission, run this script without parameters, and
//   then call the functions in the available_programs lexicon in the correct order of events for the mission
//   to build the MISSION_PLAN.
declare parameter p1 is "". 
declare parameter p2 is "". 
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
   // Don't forget to update the standalone system, above, if you change the number of parameters here.
   declare parameter argv.
   local engineName is argv:split(" ")[0].
   local newPe is argv:split(" ")[1]:tonumber(ship:orbit:periapsis).

//======== Local Variables =====
      local steerDir is "retrograde".

//=============== Begin program sequence Definition ===============================
   // The actual instructions implementing the program are in delegates, Which the initializer adds to the MISSION_PLAN.
   // In this case, the first part of the program sequence
   // is given as an anonymous function, and the second part is a function implemented in the maneuver_ctl library. 
   // If you do not like anonymous functions, you could implement a named function elsewhere and add a reference
   // to it to the MISSION_PLAN instead, like so: kernel_ctl["MissionPlanAdd"](named_function@).
   kernel_ctl["MissionPlanAdd"]("change-pe", {
      until ship:maxthrust < 1.01*maneuver_ctl["engineStat"](engineName, "thrust") and ship:maxthrust > 0.99*maneuver_ctl["engineStat"](engineName, "thrust") {
         print "staging, Max thrust: "+ship:maxthrust.
         stage. 
         wait 1.
         if ship:maxthrust < 0.99*maneuver_ctl["engineStat"](engineName, "thrust") or ship:maxthrust > 1.01*maneuver_ctl["engineStat"](engineName, "thrust") {
            print "error in programs/change-pe.ks, wrong engine thrust: staging.".
            return OP_FAIL.
         }
      }
      print "pe requested: " + newPe.
      if ship:orbit:periapsis > newPe*0.99 and ship:orbit:periapsis < newPe*1.01 return OP_FINISHED.
      if ship:orbit:periapsis < newPe set steerDir to "prograde". 
      local newSMA is phys_lib["sma"](ship:orbit:body, ship:orbit:apoapsis, newPe).
      print "sma: "+ship:orbit:semimajoraxis.
      print "sma needed: "+newSMA.
      print "mu: "+ship:orbit:body:mu.
      local newVatApo is phys_lib["VatAlt"](ship:orbit:body, ship:orbit:apoapsis, newSMA).
      print "vel at apo: "+velocityat(ship, eta:apoapsis):orbit:mag.
      print "vel at apo needed: " + newVatApo.
      local dv is abs(newVatApo - phys_lib["VatAlt"](ship:orbit:body, ship:orbit:apoapsis, ship:orbit:semimajoraxis)).//velocityat(ship, eta:apoapsis):orbit:mag).
      print "dV calculated: "+dv.
      maneuver_ctl["add_burn"](steerDir, engineName, "ap", dv).
      return OP_FINISHED.
   }).
   kernel_ctl["MissionPlanAdd"]("execute maneuver", maneuver_ctl["burn_monitor"]).
   kernel_ctl["MissionPlanAdd"]("fining", {
      if (steerDir = "prograde" and ship:periapsis < newPe*0.99 ) or (steerDir = "retrograde" and ship:periapsis > newPe*1.01) {
         if steerDir = "prograde" {
            if vang(ship:facing:forevector, ship:prograde:forevector) > 0.5
               lock throttle to 0.
            wait until vang(ship:facing:forevector, ship:prograde:forevector) < 0.5.
         } else {
            if vang(ship:facing:forevector, ship:retrograde:forevector) > 0.5
               lock throttle to 0.
            wait until vang(ship:facing:forevector, ship:retrograde:forevector) < 0.5.
         }
         lock throttle to 0.1.
         return OP_CONTINUE.
      } else if (steerDir = "prograde" and ship:periapsis > newPe*1.01) or (steerDir = "retrograde" and ship:periapsis < newPe*0.99) {
         if steerDir = "prograde" {
            set steerDir to "retrograde".
         } else {
            set steerDir to "prograde".
         }
         return OP_CONTINUE.
      }
      return OP_FINISHED.
   }).
   
         
//========== End program sequence ===============================
   
}). //End of initializer delegate
