@lazyglobal off.
// Program Template

local programName is "change-ap". //<------- put the name of the script here

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
   if not (defined phys_lib) runpath("0:/lib/physics.ks").
   
//======== Parameters used by the program ====
   declare parameter engineName.
   declare parameter newAp.
   declare parameter AOP is ship:orbit:argumentofperiapsis. //Argument of periapsis

//======== Local Variables =====
      local steerDir is "retrograde".
      if newAp:isType("String") set newAp to newAp:tonumber(-1).
      if ship:orbit:apoapsis < newAp set steerDir to "prograde". 
      if ship:orbit:periapsis > newAp {
         print "Error: New Ap is less than Pe." at(0, 0).
         shutdown.
      }

//=============== Begin program sequence Definition ===============================
   // The actual instructions implementing the program are in delegates, Which the initializer adds to the MISSION_PLAN.
   // In this case, the first part of the program sequence
   // is given as an anonymous function, and the second part is a function implemented in the maneuver_ctl library. 
   // If you do not like anonymous functions, you could implement a named function elsewhere and add a reference
   // to it to the MISSION_PLAN instead, like so: MISSION_PLAN:add(named_function@).
   MISSION_PLAN:add({
      until ship:maxthrust < 1.01*maneuver_ctl["engineStat"](engineName, "thrust") and ship:maxthrust > 0.99*maneuver_ctl["engineStat"](engineName, "thrust") {
         print "staging, Max thrust: "+ship:maxthrust.
         stage. 
         wait 5.
         if ship:maxthrust > 1.01*maneuver_ctl["engineStat"](engineName, "thrust") or ship:maxthrust < 0.99*maneuver_ctl["engineStat"](engineName, "thrust") {
            print "Error! Engine does not have the same thrust as engine: "+engineName.
            print "Expected thrust: "+maneuver_ctl["engineStat"](engineName, "thrust").
            print "Current maxthrust is: "+ship:maxthrust.
            
            return OP_FAIL.
         }
      }
      
      //Trying to account for situations where a change of AOP is desired. 
     // local burnAngle is AOP - 180.
     // if burnAngle < 0 set burnAngle to burnAngle + 360.
     // 
      if newAp = -1 or not(newAp:istype("Scalar")) return OP_FAIL.
      local newSMA is (ship:orbit:periapsis+ship:orbit:body:radius*2+newAp)/2.
      local newVatPe is phys_lib["VatAlt"](ship:orbit:body, ship:orbit:periapsis, newSMA).
      local dv is abs(newVatPe - velocityat(ship, eta:periapsis):orbit:mag).

     // if AOP > ship:orbit:argumentofperiapsis - 0.01 and AOP < ship:orbit:argumentofperiapsis + 0.01{
     //    print "adding maneuver 1".
         maneuver_ctl["add_burn"](steerDir, engineName, "pe", dv).

      //} else {
      //   print "changing AOP".
      //   local angleDistToBurn is (ship:orbit:trueanomaly-burnAngle).
      //   if angleDistToBurn < 0 set angleDistToBurn to angleDistToBurn + 360.
      //   local etaBurnAngle is angleDistToBurn/ship:orbit:period.
      //   print "adding maneuver 2".
      //   maneuver_ctl["add_burn"](steerDir, engineName, time:seconds+etaBurnAngle, dv).
      //}
      return OP_FINISHED.
   }).
   MISSION_PLAN:add(maneuver_ctl["burn_monitor"]).
   MISSION_PLAN:add({  //Fining, I think?
      if (steerDir = "prograde" and ship:apoapsis < newAp*0.995 ) or (steerDir = "retrograde" and ship:apoapsis > newAp*1.005) {
         if steerDir = "prograde" {
            if vang(ship:facing:forevector, ship:prograde:forevector) > 0.5
               lock throttle to 0.
            wait until vang(ship:facing:forevector, ship:prograde:forevector) < 0.5.
         } else {
            if vang(ship:facing:forevector, ship:retrograde:forevector) > 0.5
               lock throttle to 0.
            wait until vang(ship:facing:forevector, ship:retrograde:forevector) < 0.5.
         }
         lock throttle to abs(ship:apoapsis-newAp).
         return OP_CONTINUE.
      } else if (steerDir = "prograde" and ship:apoapsis > newAp*1.005) or (steerDir = "retrograde" and ship:apoapsis < newAp*0.995) {
         if steerDir = "prograde" {
            set steerDir to "retrograde".
         } else {
            set steerDir to "prograde".
         }
         return OP_CONTINUE.
      }
      lock throttle to 0.
      return OP_FINISHED.
   }).
   
         
//========== End program sequence ===============================
   
}. //End of initializer delegate
