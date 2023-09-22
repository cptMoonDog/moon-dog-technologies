@lazyglobal off.
local programName is "docking". //<------- put the name of the script here

kernel_ctl["availablePrograms"]:add(programName, {
  
//======== Imports needed by the program =====
   
//======== Parameters used by the program ====
   declare parameter argv.
   local tgtPort is "".
   local localPort is "".

   if argv:trim {
      if argv:split(char(34)):length > 1 { //char(34) is quotation mark
         set tgtPort to argv:split(char(34))[1]. // Quoted first parameter
         set tgtPort to tgtPort + ":"+argv:split(":")[1]:split(" ")[0].
      } else set tgtPort to argv:split(" ")[0].
      set localPort to argv:split(" ")[argv:split(" "):length-1].
      set kernel_ctl["output"] to "target: "+ tgtPort.
   } else {
      set kernel_ctl["output"] to
         "Docks with the given target port. Requires the target port to be named."
         +char(10)+"Usage: add docking [TARGET]:[PORT] [LOCAL PORT (Optional)]".
      return.
   }

//======== Local Variables =====
   // Most of these values are initial; Don't have a great amount of significance.
   local port is ship:dockingports[0].
   local standOffFore is 100. 
   local standOffVert is 0.
   local standOffLateral is 0.
   local nullZone is 0.5.

   local dist is (port:position).

   local offsetVert is dist*port:portfacing:topvector.
   local offsetLateral is dist*port:portfacing:starvector.
   local offsetFore is dist*port:portfacing:forevector.

   local vel is ship:velocity:orbit. 

   local speedVert is vel*port:portfacing:topvector.
   local speedLateral is vel*port:portfacing:starvector.
   local speedFore is vel*port:portfacing:forevector.

   local safeDistance is 0.
   
   local speedLimit is 0.

   declare function getControlInputForAxis {
      parameter offset, speed, setpoint, nullZone.
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
         if speed > 0.001 return sigmoid.
         else if speed < -0.001 return -sigmoid.
         else return 0.
      }
   }

   declare function actuateControls {
      set ship:control:fore      to getControlInputForAxis(offsetFore, speedFore, standOffFore, nullZone).
      set ship:control:top       to getControlInputForAxis(offsetVert, speedVert, standOffVert, nullZone).
      set ship:control:starboard to getControlInputForAxis(offsetLateral, speedLateral, standOffLateral, nullZone).
   }

   declare function steeringVector {
      if not(hastarget) return ship:prograde.
      else if (hastarget and not(target:istype("DockingPort"))) {
         return target:position.
      } else return target:portfacing:vector:normalized*-1.
   }

   declare function updateVectors {
      set dist          to (target:position - port:position).

      set offsetVert    to dist*port:portfacing:topvector.
      set offsetLateral to dist*port:portfacing:starvector.
      set offsetFore    to dist*port:portfacing:forevector.

      if target:istype("Vessel") {
         set vel to (target:velocity:orbit - ship:velocity:orbit).
         if dist:mag < 200 {
            for p in target:dockingports {
               if p:tag = tgtPort:split(":")[1] {
                  set target to p.
                  wait 0.
                  break.
               }
            }
            wait 0.
            set vel to (target:ship:velocity:orbit - ship:velocity:orbit).
         }
      } else {
         set vel to (target:ship:velocity:orbit - ship:velocity:orbit).
      }

      set speedVert     to vel*port:portfacing:topvector.
      set speedLateral  to vel*port:portfacing:starvector.
      set speedFore     to vel*port:portfacing:forevector.
      set nullZone to dist:mag/10.
      set speedLimit to sqrt(dist:mag)/10.
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
      lock steering to steeringVector.
      // Collect info about this vessel
      if ship:dockingports:length = 0 {
         print "No Docking ports on this vessel.".
         return OP_FAIL.
      } else if ship:dockingports:length = 1 {
         set port to ship:dockingports[0].
         if port:state:contains("Docked") return OP_FAIL.
         port:controlfrom().
      } else {
         for p in ship:dockingports {
            if p:tag = "forward" {
               set port to p.
               break.
            }
         }
         if not(port:istype("DockingPort")) set port to ship:dockingports[0].
         if port:state:contains("Docked") return OP_FAIL.
         port:controlfrom().
      }
      if not(hastarget) {
         set target to tgtPort:split(":")[0].
         wait 0.
         updateVectors().
      } else updateVectors().
      // Double the combined size of the longest parts of the bounding boxes of both vessels + 1 for good measure.
      set safeDistance to abs(
         (target:ship:bounds:relmin + target:ship:bounds:relmax):mag +
         (ship:bounds:relmin + ship:bounds:relmax):mag)*2 + 1.
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
         unlock steering.
         wait 0.
         return OP_FINISHED.
      }

      updateVectors().
      // If aligned with target port, and standoff distance is not negative (occupying same space as target) move closer.
      if (offsetVert    > -nullZone and offsetVert    < nullZone) and // Vertically aligned
         (offsetLateral > -nullZone and offsetLateral < nullZone) and // Horizontally aligned
         standOffFore > 1 and standOffFore > max(0, offsetFore - 1) {

         if speedFore < (offsetFore/safeDistance)*speedLimit {
            set standOffFore to max(0, standOffFore - 1). // Reduce standoff distance.
         } 
      } else { 
         // Parallel to target port, but target port is behind us.  Navigate in box shape around target vessel.
         if offsetFore < 0 { // 
            // Move off to a safe distance, in the same direction as all current offsets (away).
            set standOffVert to (offsetVert/abs(offsetVert))*safeDistance.
            set standOffLateral to (offsetLateral/abs(offsetLateral))*safeDistance.
            set standOffFore to (offsetFore/abs(offsetFore))*safeDistance.
         }
         // We are at a "safedistance" in at least one direction normal to the port.  Reset forward standoff to positive number.
         if abs(offsetVert) > safeDistance-1 or abs(offsetLateral) > safeDistance-1 {
            set standOffFore to safeDistance.
         }
         // We are at a "safedistance" in the forward direction.  Move into alignment with target port.
         if offsetFore > safeDistance-1 {
            set standOffVert to 0.
            set standOffLateral to 0.
         }
      }
      
      actuateControls().
      wait 0.
      return OP_CONTINUE.
   }).
//========== End program sequence ===============================

}). //End of initializer delegate
