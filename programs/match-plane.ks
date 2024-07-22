@lazyglobal off.
// Program Template

local programName is "match-plane". //<------- put the name of the script here

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
   // Don't forget to update the standalone system, above, if you change the number of parameters here.
   declare parameter argv.
   local engineName is "".
   local targetObject is "".
   if argv:split(" "):length >= 2 {
      set engineName to argv:split(" ")[0].
      if not (maneuver_ctl["engineDef"](engineName)) return OP_FAIL.
      if argv:split(char(34)):length > 1 set targetObject to argv:split(char(34))[1]. // Quoted second parameter
      else {
         set targetObject to argv:split(" ")[1].
         //set kernel_ctl["output"] to "target: "+ targetObject.
      }
   } else {
      set kernel_ctl["output"] to
         "Creates and executes a maneuver to match orbital planes with the given target"
         +char(10)+"Usage: Q match-plane [ENGINE-NAME] [TARGET] | [LAN]:[INC]".
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
      if targetObject:typename = "String" {
         if targetObject:split(":"):length > 1 
            set targetObject to createorbit(
               targetObject:split(":")[1]:tonumber(-1), // Inclination
               0, // Eccentricity
               ship:body:radius*1.5, // SMA
               targetObject:split(":")[0]:tonumber(-1), // LAN
               0, // Argument of Periapsis
               0, // Mean Anomaly at epoch
               0, // epoch
               ship:body
            ).
         else if bodyexists(targetObject) 
            set targetObject to body(targetObject).
         else set targetObject to vessel(targetObject).
      }
      //set target to targetObject.
      // I'm not sure the following works for the ship.  I think it works for other orbitables.
      local myPlane is phys_lib["obtPlaneVector"](ship).

      local theirPlane is phys_lib["obtPlaneVector"](targetObject).
      local AN_DN is vcrs(myPlane, theirPlane).
      local dInc is vang(myPlane, theirPlane).

      local angleToANDNNode is vang(up:forevector, AN_DN).  //Great, but am I coming or going?
      local velAngleToANDNNode is vang(ship:prograde:forevector, AN_DN).
      if velAngleToANDNNode < 90 set angleToANDNNode to vang(up:forevector, AN_DN). // Heading toward, and this should give less than 180 degrees.
      else set angleToANDNNode to 180-angleToANDNNode.  // Should switch it to the other direction
      
      local minEtaBP is (angleToANDNNode)*((ship:orbit:period)/360).

      local dvNormal is ship:velocity:orbit:mag*sin(dInc).
      local dvPrograde is ship:velocity:orbit:mag*cos(dInc)-ship:velocity:orbit:mag.
      add(node(time:seconds+minEtaBP, 0, dvNormal, dvPrograde)).

      maneuver_ctl["add_burn"]("node", engineName, "node", nextnode:deltav:mag).
      return OP_FINISHED.
   }).
   kernel_ctl["MissionPlanAdd"](programName, maneuver_ctl["burn_monitor"]).
         
//========== End program sequence ===============================
   
}). //End of initializer delegate
