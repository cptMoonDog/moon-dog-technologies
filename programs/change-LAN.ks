@lazyglobal off.
// Program Template

local programName is "change-LAN". //<------- put the name of the script here

// Header allowing for standalone operation.
//   If this program is to be used as part of a complete mission, run this script without parameters, and
//   then call the functions in the available_programs lexicon in the correct order of events for the mission
//   to build the MISSION_PLAN.
declare parameter p1 is "". 
declare parameter p2 is "". 
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
   // Don't forget to update the standalone system, above, if you change the number of parameters here.
   declare parameter argv.
   local engineName is "".
   local newLAN is "".
   if argv:split(" "):length = 2 {
      set engineName to argv:split(" ")[0].
      if not (maneuver_ctl["engineDef"](engineName)) return OP_FAIL.
      set newLAN to argv:split(" ")[1]:tonumber(ship:orbit:LAN).
   } else {
      set kernel_ctl["output"] to
         "Changes the Longitude of the Ascending Node (LAN/RAAN)."
         +char(10)+"Usage: add-program change-inc [ENGINE-NAME] [NEW-LONGITUDE]".
      return.
   }

//======== Local Variables =====

//=============== Begin program sequence Definition ===============================
   // The actual instructions implementing the program are in delegates, Which the initializer adds to the MISSION_PLAN.
   // In this case, the first part of the program sequence
   // is given as an anonymous function, and the second part is a function implemented in the maneuver_ctl library. 
   // If you do not like anonymous functions, you could implement a named function elsewhere and add a reference
   // to it to the MISSION_PLAN instead, like so: kernel_ctl["MissionPlanAdd"](named_function@).
   kernel_ctl["MissionPlanAdd"]("change-LAN", {
      local count is 0.
      until ship:maxthrust < 1.01*maneuver_ctl["engineStat"](engineName, "thrust") and ship:maxthrust > 0.99*maneuver_ctl["engineStat"](engineName, "thrust") {
         print "staging, Max thrust: "+ship:maxthrust.
         stage. 
         wait until stage:ready.
         if ship:maxthrust = 0 print "Likely a staging problem: Check yo' stagin!".
         if count > 2 {
            return OP_FAIL.
         }
         set count to count +1.
      }
      local ensuredSPV is solarprimevector-ship:body:position. // From SOI origin
      //local ensuredSPV is lookdirup(solarprimevector, north:forevector).
      //local lanVec is angleaxis(ship:orbit:lan, ensuredSPV:topvector):forevector.
      local lanVec is ensuredSPV*angleaxis(ship:orbit:lan, north:forevector-ship:body:position). // From SOI origin
      local angleToAN is vang(ship:position-ship:body:position, lanVec).         // From SOI origin
      local angleToDN is vang(ship:position-ship:body:position, -1*lanVec).         // From SOI origin
      // It does not matter whether it is a prograde or retrograde orbit.
      // Or if we are closer to AN or DN
      if ship:geoposition:lat > 0 set angleToAN to 360 - angleToAN.      // Northern hemisphere; Past AN
      else set angleToDN to 360 - angleToDN.                                  // Southern hemisphere; Past DN

      //Assuming circular orbit:
      local ttAN is (ship:orbit:period/360)*angleToAN.
      local ttDN is (ship:orbit:period/360)*angleToDN.

      local ttBPAfter is ttAN + ship:orbit:period/4.
      if ttBPAfter > ship:orbit:period set ttBPAfter to ttBPAfter - ship:orbit:period.
      local ttBPBefore is ttDN + ship:orbit:period/4.
      if ttBPBefore > ship:orbit:period set ttBPBefore to ttBPBefore - ship:orbit:period.

      // As far as I can determine, the angular change of the LAN is the same as the change in the angle between the new and old orbits at the burn point 90 degrees from the AN.
      local dLAN is newLAN - ship:orbit:LAN.
      if dLAN > 180 set dLAN to dLAN - 360.
      else if dLAN < -180 set dLAN to 360 + dLAN.
      
      local dvNormal is ship:velocity:orbit:mag*sin(dLAN). // Gives negative for negative dLAN
      local dvPrograde is ship:velocity:orbit:mag*cos(dLAN)-ship:velocity:orbit:mag.
      // If ship orbit is prograde, and you burn normal before the AN, the AN will decrease. (Angle is measured counterclockwise from above)
      // after, the AN will increase.
      // If ship orbit is retrograde, and you burn normal (South) before the AN, the AN will decrease.
      // after the AN will increase.
      // In both cases, Normal before decreases, 

      // if dLAN is positive, that means increase LAN, or anti-normal before, and normal after.
      // if dLAN is negative, that means decrease LAN, or normal before, and anti-normal after.
      // dvNormal has the same sign as dLAN.
      if ttBPBefore < ttBPAfter {
         add(node(ttBPBefore+time:seconds, 0, -dvNormal, dvPrograde)).
      } else {
         add(node(ttBPAfter+time:seconds, 0, dvNormal, dvPrograde)).
      }

      maneuver_ctl["add_burn"]("node", engineName, "node", nextnode:deltav:mag).
      return OP_FINISHED.
   }).
   kernel_ctl["MissionPlanAdd"]("execute maneuver", maneuver_ctl["burn_monitor"]).
         
//========== End program sequence ===============================
   
}. //End of initializer delegate
