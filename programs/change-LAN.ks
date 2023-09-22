@lazyglobal off.
local programName is "change-LAN". //<------- put the name of the script here

kernel_ctl["availablePrograms"]:add(programName, {
   //One time initialization code.
   //   Question: Why not simply have a script file with the contents of the initializer delegate?  Why the extra layers?
   //   Answer: It seems that the memory area for parameters passed to scripts is always the same.  So, when 
   //           a script defines a function to be called later, any additional script called with parameters will
   //           clobber the parameter intended for the first one.  The parameter below will be preserved and its value
   //           will remain available to the program, as long as the program is written within this scope, 
  
//======== Imports needed by the program =====
   if not (defined maneuver_ctl) kernel_ctl["import-lib"]("lib/maneuver_ctl").
   if not (defined phys_lib) kernel_ctl["import-lib"]("lib/physics").
   
//======== Parameters used by the program ====
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
         +char(10)+"Usage: add change-LAN [ENGINE-NAME] [NEW-LONGITUDE]".
      return.
   }

//======== Local Variables =====

//=============== Begin program sequence Definition ===============================
   // The actual instructions implementing the program are in delegates, Which the initializer adds to the MISSION_PLAN.
   // In this case, the first part of the program sequence
   // is given as an anonymous function, and the second part is a function implemented in the maneuver_ctl library. 
   // If you do not like anonymous functions, you could implement a named function elsewhere and add a reference
   // to it to the MISSION_PLAN instead, like so: kernel_ctl["MissionPlanAdd"](named_function@).
   kernel_ctl["MissionPLanAdd"](programName, {
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
      local angleToAN is vang(ship:position-ship:body:position, LANVector()).         // From SOI origin
      local angleToDN is vang(ship:position-ship:body:position, -1*LANVector()).         // From SOI origin
      // It does not matter whether it is a prograde or retrograde orbit.
      // Or if we are closer to AN or DN

      // Implementing Null change in inclination:
      local angleOfBP is (newLAN+ship:orbit:LAN)/2 - 90.
      local vectorOfBP is vxcl(ship:angularvel:normalized, angleaxis(angleOfBP, ship:body:angularvel:normalized)*solarprimevector).
      local angleToBP is vang(-ship:body:position, vectorOfBP).
      local dPlane is arccos((sin(ship:orbit:inclination)^2)*(cos(ship:orbit:lan-newLAN)-1)+1).
      //local dPlane is arccos((sin(ship:orbit:inclination)^2)*(cos(ship:orbit:lan)*cos(newLAN)+sin(ship:orbit:lan)*sin(newLAN)-1)+1).
      //local dPlane is arccos((sin(ship:orbit:inclination)^2)*cos(newLAN-ship:orbit:LAN)).
      //local dPlane is arccos((sin(ship:orbit:inclination)^2)*cos(ship:orbit:LAN-newLAN)).

      //if vang(ship:velocity:orbit, LANVector()) < 90 and vang(ship:velocity:orbit, north:forevector) > 90 { // Heading toward AN, heading South
      //   set angleToBP to angleToAN-90.      
      //} else if vang(ship:velocity:orbit, LANVector()) < 90 and vang(ship:velocity:orbit, north:forevector) < 90 {  // Heading toward AN, heading North.
      //   set angleToBP to angleToAN+90. 
      //} else if vang(ship:velocity:orbit, LANVector()) > 90 and vang(ship:velocity:orbit, north:forevector) < 90 {  // Heading away from AN, heading North.
      //   set angleToBP to angleToDN-90. 
      //} else if vang(ship:velocity:orbit, LANVector()) > 90 and vang(ship:velocity:orbit, north:forevector) > 90 {  // Heading away from AN, heading South.
      //   set angleToBP to angleToDN+90. 
      //}

      //Assuming circular orbit:
      local ttBP is (ship:orbit:period/360)*angleToBP.

      local dvNormal is ship:velocity:orbit:mag*sin(dPlane). // Gives negative for negative dLAN
      local dvPrograde is ship:velocity:orbit:mag*cos(dPlane)-ship:velocity:orbit:mag.

      add(node(ttBP+time:seconds, 0, -dvNormal, dvPrograde)).

      maneuver_ctl["add_burn"]("node", engineName, "node", nextnode:deltav:mag).
      return OP_FINISHED.
   }).
   kernel_ctl["MissionPLanAdd"](programName, maneuver_ctl["burn_monitor"]).
         
//========== End program sequence ===============================
   
}). //End of initializer delegate
