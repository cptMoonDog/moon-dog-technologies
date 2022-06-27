@lazyglobal off.
// Program Template

local programName is "orient-to-max-solar". //<------- put the name of the script here

// Header allowing for standalone operation.
//   If this program is to be used as part of a complete mission, run this script without parameters, and
//   then call the functions in the available_programs lexicon in the correct order of events for the mission
//   to build the MISSION_PLAN.
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
   
//======== Parameters used by the program ====
   declare parameter argv.

//======== Local Variables =====
      local panels is ship:modulesnamed("ModuleDeployableSolarPanel").
      local primary is panels[0]. // Ideally, the biggest.
      local panelFacingVector is v(0,0,0).
      local panelTopVector is v(0,0,0).
      local steeringVector is body("Sun"):position:normalized.

//=============== Begin program sequence Definition ===============================
   // The actual instructions implementing the program are in delegates, Which the initializer adds to the MISSION_PLAN.
   // In this case, the first part of the program sequence
   // is given as an anonymous function, and the second part is a function implemented in the maneuver_ctl library. 
   // If you do not like anonymous functions, you could implement a named function elsewhere and add a reference
   // to it to the MISSION_PLAN instead, like so: kernel_ctl["MissionPlanAdd"](named_function@).
   kernel_ctl["MissionPLanAdd"](programName, {
      set panels            to ship:modulesnamed("ModuleDeployableSolarPanel").
      set primary           to panels[0]. // Ideally, the biggest.
      set panelFacingVector to v(0,0,0).
      set panelTopVector    to v(0,0,0).
      set steeringVector    to body("Sun"):position:normalized.
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
         if panelTopVector:mag = 0 set panelFacingVector to vcrs(-primary:part:facing:topvector, panelFacingVector).
         else set panelFacingVector to vcrs(panelFacingVector, panelTopVector).
      } 


      //TODO ************** Needs more testing, particularly the sign adjustments
      // The trick here, is to turn a local difference into a global difference.
      local pitchDiff is vang(ship:facing:forevector, vxcl(ship:facing:starvector, panelFacingVector)). // unsigned pitch
      if vang(vxcl(ship:facing:starvector, panelFacingVector), ship:facing:topvector) > 90 set pitchDiff to 90-pitchDiff.

      local yawDiff is vang(ship:facing:forevector, vxcl(ship:facing:topvector, panelFacingVector)). // unsigned Yaw
      if vang(vxcl(ship:facing:topvector, panelFacingVector), ship:facing:forevector) > 91 set yawDiff to -yawDiff.

      local rollDiff is vang(ship:facing:topvector, vxcl(ship:facing:forevector, panelTopVector)). // unsigned roll
      if vang(vxcl(ship:facing:forevector, panelTopVector), ship:facing:topvector) > 90 set rollDiff to 180-rollDiff.
      
      //local steeringVector is body("Sun"):position:normalized*rotatefromto(ship:facing:forevector:normalized, panelFacingVector:normalized).
      //local steeringVector is body("Sun"):position:normalized*rotatefromto(ship:facing:forevector:normalized, panelFacingVector:normalized).
      local steeringVector is body("Sun"):position:normalized*R(pitchDiff, yawDiff, rollDiff).
      //local steeringVector is body("Sun"):position:normalized*angleaxis(yawDiff, vcrs(body("Sun"):position, solarprimevector))*angleaxis(rollDiff, body("Sun"):position).
      
      print vang(body("Sun"):position, panelFacingVector) at(0, 5).
      print vang(body("Sun"):position, panelTopVector) at(0, 6).
      print yawDiff at(0, 7).
      print rollDiff at(0, 8).
      print pitchDiff at(0, 9).
      
      lock steering to steeringVector.
      return OP_CONTINUE.
   }).
         
//========== End program sequence ===============================
   
}). //End of initializer delegate
