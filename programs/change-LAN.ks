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
         +char(10)+"Usage: add-program change-LAN [ENGINE-NAME] [NEW-LONGITUDE]".
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
      local LANVector is {
         return angleaxis(ship:orbit:lan, ship:body:angularvel:normalized)*solarprimevector. //Taken from KSLib.  Never would have thought of angularVel in a million years.
      }.
      //clearvecdraws().
local lanVecArrow is vecdraw(
                        v(0, 0, 0), 
                        {return (north:forevector+ship:orbit:position)*100000.},
                        RGB(1, 0, 0),
                        "LAN",
                        1,
                        true,
                        0.2,
                        true,
                        true).
      local angleToAN is vang(ship:position-ship:body:position, LANVector()).         // From SOI origin
      local angleToDN is vang(ship:position-ship:body:position, -1*LANVector()).         // From SOI origin
      // It does not matter whether it is a prograde or retrograde orbit.
      // Or if we are closer to AN or DN
      local angleToBP is 0.
      if vang(ship:velocity:orbit, LANVector()) < 90 and vang(ship:velocity:orbit, north:forevector) > 90 { // Heading toward AN, heading South
         set angleToBP to angleToAN-90.      
      } else if vang(ship:velocity:orbit, LANVector()) < 90 and vang(ship:velocity:orbit, north:forevector) < 90 {  // Heading toward AN, heading North.
         set angleToBP to angleToAN+90. 
      } else if vang(ship:velocity:orbit, LANVector()) > 90 and vang(ship:velocity:orbit, north:forevector) < 90 {  // Heading away from AN, heading North.
         set angleToBP to angleToDN-90. 
      } else if vang(ship:velocity:orbit, LANVector()) > 90 and vang(ship:velocity:orbit, north:forevector) > 90 {  // Heading away from AN, heading South.
         set angleToBP to angleToDN+90. 
      }

      //Assuming circular orbit:
      local ttBP is (ship:orbit:period/360)*angleToBP.

      // As far as I can determine, the angular change of the LAN is the same as the change in the angle between the new and old orbits at the burn point 90 degrees from the AN.
      local dLAN is newLAN - ship:orbit:LAN.
      local dPlane is arctan(sin(ship:orbit:inclination)*tan(dLAN)).
      set kernel_ctl["status"] to dPlane:tostring().
      //if dLAN > 180 set dLAN to dLAN - 360.
      //else if dLAN < -180 set dLAN to 360 + dLAN.
      
      local dvNormal is ship:velocity:orbit:mag*sin(dPlane). // Gives negative for negative dLAN
      local dvPrograde is ship:velocity:orbit:mag*cos(dPlane)-ship:velocity:orbit:mag.

      add(node(ttBP+time:seconds, 0, -dvNormal, dvPrograde)).

      maneuver_ctl["add_burn"]("node", engineName, "node", nextnode:deltav:mag).
      return OP_FINISHED.
   }).
   kernel_ctl["MissionPlanAdd"]("execute maneuver", maneuver_ctl["burn_monitor"]).
         
//========== End program sequence ===============================
   
}. //End of initializer delegate
