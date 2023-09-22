@lazyglobal off.
// Program Template

local programName is "docking-claw". //<------- put the name of the script here

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
   // Don't forget to update the standalone system, above, if you change the number of parameters here.
   declare parameter argv.
   local tgtPart is "".
   local localClaw is "".

   if argv:split(" "):length = 2 {
      set tgtPart to argv:split(" ")[0].
      set localClaw to argv:split(" ")[1].
   } else if argv:split(" ")[0] {
      set tgtPart to argv:split(" ")[0].
   } else {
      set kernel_ctl["output"] to
         "Attempts to capture with the claw, the part on the target vessel that has the given tag."
         +char(10)+"Usage: add docking [TARGET]:[TAG] [LOCAL CLAW (Optional)]".
      return.
   }

//======== Local Variables =====
   declare function getControlInputForAxis {
      parameter offset, speed, setpoint, nullZone.
      local speedLimit is 0.5.
      // If not in nullZone
      if offset < setpoint - nullZone or setpoint + nullZone < offset{
         local error is abs(offset-setpoint).
         local sigmoid is error/sqrt(1+error^2). 
         // Accelerate toward nullZone.
         if offset > setpoint and speed > -speedLimit {
            return sigmoid.
         } else if offset < setpoint and speed < speedLimit {
            return -sigmoid.
         } else return 0.
      } else { // Else null your rates.
         local pvar is 3*speed.
         local sigmoid is abs(pvar)/sqrt(1+abs(pvar)^2).
         if speed > 0.04 return sigmoid.
         else if speed < -0.04 return -sigmoid.
         else return 0.
      }
   }

   declare function steeringVector {
      if not(hastarget) return ship:prograde.
      if not(targetPart:istype("Part")) return target:position.
      return targetPart:facing:vector:normalized*-1.
   }

   local targetPart is 0.
   
   local claw is ship:partsnamed("smallClaw")[0].
   local standOffFore is 100. // Don't approach closer than 100m until aligned.
   local standOffVert is 0.
   local standOffLateral is 0.
   local nullZone is 0.5.
   local approachSpeed is 10.

   local dist is (claw:position).

   local offsetVert is dist*claw:facing:topvector.
   local offsetLateral is dist*claw:facing:starvector.
   local offsetFore is dist*claw:facing:forevector.

   local vel is ship:velocity:orbit. //(target:ship:velocity:orbit - ship:velocity:orbit).

   local speedVert is vel*claw:facing:topvector.
   local speedLateral is vel*claw:facing:starvector.
   local speedFore is vel*claw:facing:forevector.

   local safeDistance is 25.
   
   declare function updateVectors {
      set dist          to (targetPart:position - claw:position).

      set offsetVert    to dist*claw:facing:topvector.
      set offsetLateral to dist*claw:facing:starvector.
      set offsetFore    to dist*claw:facing:forevector.

      if target:istype("Vessel") {
         set vel to (target:velocity:orbit - ship:velocity:orbit).
         if dist:mag < 200 and not(targetPart:istype("Part")) { // targetPart is still target vessel.
            local p is target:partstagged(tgtPart:split(":")[1])[0].
            set targetPart to p.
            wait 0.
         }
      } else {
         set vel to (target:ship:velocity:orbit - ship:velocity:orbit).
      }

      set speedVert     to vel*claw:facing:topvector.
      set speedLateral  to vel*claw:facing:starvector.
      set speedFore     to vel*claw:facing:forevector.
   }

   declare function actuateControls {
      set ship:control:fore      to getControlInputForAxis(offsetFore, speedFore, standOffFore, nullZone).
      set ship:control:top       to getControlInputForAxis(offsetVert, speedVert, standOffVert, nullZone).
      set ship:control:starboard to getControlInputForAxis(offsetLateral, speedLateral, standOffLateral, nullZone).
   }


//=============== Begin program sequence Definition ===============================
   // The actual instructions implementing the program are in delegates, Which the initializer adds to the MISSION_PLAN.
   // In this case, the first part of the program sequence
   // is given as an anonymous function, and the second part is a function implemented in the maneuver_ctl library. 
   // If you do not like anonymous functions, you could implement a named function elsewhere and add a reference
   // to it to the MISSION_PLAN instead, like so: kernel_ctl["MissionPlanAdd"](named_function@).

   // Got some inspiration from: https://www.reddit.com/r/Kos/comments/2n78zf/i_finally_did_it_automated_rendezvous_and_docking/

   // Setup
   kernel_ctl["MissionPlanAdd"](programName, {
      if not(hastarget) {
         set target to tgtPart:split(":")[0].
         set targetPart to target:partstagged(tgtPart:split(":")[1])[0].
      }
      lock steering to steeringVector().
      // Collect info about this vessel
      if ship:partsnamed("smallClaw"):length = 0 {
         print "No Claw on this vessel.".
         return OP_FAIL.
      } else if ship:partsnamed("smallClaw"):length = 1 {
         set claw to ship:partsnamed("smallClaw")[0].
         claw:getmodule("ModuleGrappleNode"):doevent("control from here").
      } else {
         for p in ship:partsnamed("smallClaw") {
            if p:tag = localClaw {
               set claw to p.
               break.
            }
         }
         if not(claw) set claw to ship:partsnamed("smallClaw")[0].
         claw:getmodule("ModuleGrappleNode"):doevent("control from here").
      }
      if not(hastarget) {
         set target to tgtPart:split(":")[0].
         wait 0.
         updateVectors().
      } else updateVectors().
         //local vess is vessel(tgtPart:split(":")[0]).
         //for p in vess:dockingports {
            //if p:tag = tgtPart:split(":")[1] {
               //set target to p.
               //wait 0.
               //break.
            //}
         //}
         //if not(hastarget) or (hastarget and not(target:istype("DockingPort"))) {
            //print "Select docking port." at(0, 3).
            //return OP_CONTINUE.
         //}
      //} 
      // Wait until port is aligned with target port.
      //if vang(port:portfacing:forevector, target:portfacing:vector:normalized*-1) > 0.5 return OP_CONTINUE.
     // else
      if not RCS {
         RCS on.
         return OP_FINISHED.
      } else return OP_FINISHED.
   }).

   // Maneuvering
   kernel_ctl["MissionPlanAdd"](programName, {
      // If target disappears that means docking was successful.
      if not(hastarget) {
         RCS off.
         return OP_FINISHED.
      }

      updateVectors().
      // If aligned with target claw, and standoff distance is not negative (occupying same space as target) move closer.
      if (offsetVert    > -nullZone and offsetVert    < nullZone) and // Vertically aligned
         (offsetLateral > -nullZone and offsetLateral < nullZone) { // Horizontally aligned
         if standOffFore > 1 and standOffFore > max(0, offsetFore - 1) { // Hold 1 meter in front of target, 
            if speedFore < (offsetFore/safeDistance)*approachSpeed {
               set standOffFore to standOffFore - 1. // Reduce standoff distance.
            } 
         } else if speedFore < 0.6 and offsetFore <= 1 { // Final push
            set standOffFore to 0.
         }
      } else { 
         // Parallel to target part, but target part is behind us.  Navigate in box shape around target vessel.
         if offsetFore < 0 { // 
            // Move off to a safe distance, in the same direction as all current offsets (away).
            set standOffVert to (offsetVert/abs(offsetVert))*safeDistance.
            set standOffLateral to (offsetLateral/abs(offsetLateral))*safeDistance.
            set standOffFore to (offsetFore/abs(offsetFore))*safeDistance.
            set nullZone to 5. // Relax nullZone, because do not need precision when far from target.
         }
         // We are at a "safedistance" in at least one direction normal to the part.  Reset forward standoff to positive number.
         if abs(offsetVert) > safeDistance-5 or abs(offsetLateral) > safeDistance-5 {
            set standOffFore to safeDistance.
            set nullZone to 0.5.
         }
         // We are at a "safedistance" in the forward direction.  Move into alignment with target part.
         if offsetFore > safeDistance-5 {
            set standOffVert to 0.
            set standOffLateral to 0.
            set nullZone to 0.5.
         }
      }
      
      actuateControls().
      wait 0.
      return OP_CONTINUE.
   }).
//========== End program sequence ===============================

}). //End of initializer delegate
