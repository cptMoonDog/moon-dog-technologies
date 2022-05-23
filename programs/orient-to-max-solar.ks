@lazyglobal off.
// Program Template

local programName is "orient-to-max-solar". //<------- put the name of the script here

// Header allowing for standalone operation.
//   If this program is to be used as part of a complete mission, run this script without parameters, and
//   then call the functions in the available_programs lexicon in the correct order of events for the mission
//   to build the MISSION_PLAN.
declare parameter p1 is "". 
declare parameter p2 is "". 
if not (defined available_programs) declare global available_programs is lexicon().

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
   //if not (defined phys_lib) runpath("0:/lib/physics.ks").
   
//======== Parameters used by the program ====
   declare parameter argv.

//======== Local Variables =====
   local lastLightMag is -1.
   local lastVector is ship:facing:forevector.
   local lastTime is time:seconds.
   local rotMag is 10.
   local axis is "roll".

   declare function setSteeringLock {
      set lastVector to ship:facing:forevector.
      if axis = "roll" lock steering to lastVector + R(0, 0, rotMag).
      if axis = "yaw" lock steering to lastVector + R(0, rotMag, 0).
      if axis = "pitch" lock steering to lastVector + R(rotMag, 0, 0).
   }
   

//=============== Begin program sequence Definition ===============================
   // The actual instructions implementing the program are in delegates, Which the initializer adds to the MISSION_PLAN.
   // In this case, the first part of the program sequence
   // is given as an anonymous function, and the second part is a function implemented in the maneuver_ctl library. 
   // If you do not like anonymous functions, you could implement a named function elsewhere and add a reference
   // to it to the MISSION_PLAN instead, like so: kernel_ctl["MissionPlanAdd"](named_function@).
   kernel_ctl["MissionPlanAdd"]("orient-to-max-solar", {
      local panels is ship:modulesnamed("ModuleDeployableSolarPanel").
      local panelFacingVector is v(0,0,0).
      local averageAngleOfIncidence is 0.
      for p in panels {
         if p:part:title = "OX-STAT Photovoltaic Panels" or p:part:title = "OX-STAT-XL Photovoltaic Panels" set panelFacingVector to panelFacingVector -p:part:facing:topvector. // 
         else set panelFacingVector to panelFacingVector +p:part:facing:forevector. // Works for the shielded 1x6
      }
      lock steering to panelFacingVector. //TODO steer this vector toward the sun.
      wait 5.
         
      return OP_FINISHED.
   }).
   
         
//========== End program sequence ===============================
   
}. //End of initializer delegate
