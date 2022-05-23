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
    local primary is panels[0]. // Ideally, the biggest.
    local panelFacingVector is v(0,0,0).
    local panelTopVector isv(0,0,0).
    // The part:facing:forevector is parallel with the surface the part is attached to.
    // the topvector is perpendicular to the surface.
    // The fixed panels face the opposite direction of the topvector, and 
    // the rotating panels can face any direction parallel with the surface.
    // Therefore, the vector to point at the sun, is the sum of the negative
    // topvectors of the fixed panels, and any convenient vector parallel to the surface for rotating panels, like facing:forevector.
    for p in panels {
       if p:part:mass > primary:part:mass set primary to p.
       set panelTopVector to panelTopVector -p:part:facing:topvector*p:part:mass.
       set panelFacingVector to panelFacingVector +p:part:facing:forevector*p:part:mass.
    }
    // Fixed panel array
    if primary:part:title = "OX-STAT Photovoltaic Panels" or primary:part:title = "OX-STAT-XL Photovoltaic Panels" { 
       if panelTopVector:mag = 0 { // Symmetrical, panels facing radially outward
          set panelFacingVector to -primary:part:facing:topvector.
       } else { 
          set panelFacingVector to panelTopVector.
       } 
    } else { // Rotating panel array, probably
       // Symmetrical radial array
       if panelTopVector:mag = 0 set panelFacingVector to vcrs(-primary:part:facing:topvector, panelFacingVector)).
       else set panelFacingVector to vcrs(panelFacingVector, panelTopVector).
    } 
    
   
    lock steering to body("Sun"):position*rotatefromto(ship:facing:forevector:normalized, panelFacingVector:normalized).
    
      wait 5.
         
      return OP_FINISHED.
   }).
   
         
//========== End program sequence ===============================
   
}. //End of initializer delegate
