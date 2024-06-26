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

   local safeDistance is 100.
   
   local speedLimit is 0.

   declare function getControlInputForAxis {
      parameter offset, speed, setpoint, nullZone, sensitivity.
      // If not in nullZone
      if offset < setpoint - max(0.05, nullZone) or offset > setpoint + max(0.05, nullZone) {
         // Accelerate toward nullZone.
         if offset > setpoint and speed > -speedLimit {
            return +max(1, (abs(offset)-nullZone)/sqrt(nullZone+(abs(offset) - nullZone)^2)).
         } else if offset < setpoint and speed < speedLimit {
            return -max(1, (abs(offset)-nullZone)/sqrt(nullZone+(abs(offset) - nullZone)^2)).
         } else return 0.
      } else { // Else null your rates.
         local sigmoid is 0.
         local error is speed.
         local tuningFactor is 1/sensitivity.
         local scale is abs(nullZone/(offset - setpoint))*tuningFactor.
         set sigmoid to error/sqrt(scale+error^2).
         return sigmoid.
      }
   }

   declare function actuateControls {
      set ship:control:fore      to getControlInputForAxis(offsetFore, speedFore, standOffFore, nullZone, 15).
      set ship:control:top       to getControlInputForAxis(offsetVert, speedVert, standOffVert, nullZone, 40).
      set ship:control:starboard to getControlInputForAxis(offsetLateral, speedLateral, standOffLateral, nullZone, 20).
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
            if tgtPort:split(":"):length > 1 for p in target:dockingports {
               if p:tag = tgtPort:split(":")[1] {
                  set target to p.
                  wait 0.
                  break.
               }
            }
            else if target:dockingPorts:length = 0 {
               set kernel_ctl["output"] to "No docking ports on target".
            }
            else set target to target:dockingPorts[0].
            wait 0.
            set vel to (target:ship:velocity:orbit - ship:velocity:orbit).
         }
      } else if hastarget {
         set vel to (target:ship:velocity:orbit - ship:velocity:orbit).
         wait 0.
         // Double the combined size of the longest parts of the bounding boxes of both vessels + 1 for good measure.
         if hastarget set safeDistance to abs(
            (target:ship:bounds:relmin + target:ship:bounds:relmax):mag +
            (ship:bounds:relmin + ship:bounds:relmax):mag)*2 + 1.
      }

      set speedVert     to vel*port:portfacing:topvector.
      set speedLateral  to vel*port:portfacing:starvector.
      set speedFore     to vel*port:portfacing:forevector.
      set nullZone to min(dist:mag/10, 1).
      set speedLimit to sqrt(dist:mag)/15.

   }

   declare function debuggingOutput {
      
      print "nullZone: "+round(nullZone, 2)+"           " at(0, 10).

      print "Control Fore: "+round(ship:control:fore, 2)+"         " at(0, 12).
      print "Control Vert: "+round(ship:control:top, 2)+"         " at(0, 13).
      print "Control Star: "+round(ship:control:starboard, 2)+"        " at(0, 14).

      print "standOffFore: "+round(standOffFore, 2)+"         " at(0, 16).
      print "standOffVert: "+round(standOffVert, 2)+"         " at(0, 17).
      print "standOffLateral: "+round(standOffLateral, 2)+"        " at(0, 18).

      print "OffsetFore: "+round(offsetFore, 2)+"         " at(0, 20).
      print "OffsetVert: "+round(offsetVert, 2)+"         " at(0, 21).
      print "OffsetLateral: "+round(offsetLateral, 2)+"        " at(0, 22).

      print "speedFore: "+round(speedFore, 2)+"            " at(0, 24).
      print "speedvert: "+round(speedVert, 2)+"            " at(0, 25).
      print "speedLateral: "+round(speedLateral, 2)+"            " at(0, 26).
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
      if not(hastarget) or not(target:istype("Vessel")) set target to tgtPort:split(":")[0].
      wait 0.
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
      set dist to (target:position - port:position).
      set vel to (target:velocity:orbit - ship:velocity:orbit).
      set safeDistance to abs(
         (target:bounds:relmin + target:bounds:relmax):mag +
         (ship:bounds:relmin + ship:bounds:relmax):mag)*2 + 1.
      if dist:mag < safeDistance - nullZone {
         if vel:mag < 1 {
            RCS on.
            set ship:control:fore to -target:position*ship:facing:forevector/target:position:mag.
            set ship:control:top to -target:position*ship:facing:topvector/target:position:mag.
            set ship:control:starboard to -target:position*ship:facing:starvector/target:position:mag.
         } else {
            set ship:control:fore to 0.
            set ship:control:top to 0.
            set ship:control:starboard to 0.
         }
         return OP_CONTINUE.
      } else RCS off.
      updateVectors().
      lock steering to steeringVector().
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
      debuggingOutput().
      // If aligned with target port, and standoff distance is not negative (occupying same space as target) move closer.
      if (offsetVert    > -nullZone and offsetVert    < nullZone) and // Vertically aligned
         (offsetLateral > -nullZone and offsetLateral < nullZone) // Horizontally aligned
         {
         //standOffFore > 1 and standOffFore > max(0, offsetFore - 1) {

         if speedFore < (offsetFore/safeDistance)*speedLimit {
            set standOffFore to max(0, standOffFore - 1). // Reduce standoff distance.
         } 
         actuateControls().
         wait 0.
         return OP_CONTINUE.
      } else { 
         if offsetFore > safeDistance - nullZone {
         // We are at a "safedistance" in the forward direction.  Move into alignment with target port.
            set standOffVert to 0.
            set standOffLateral to 0.
         } else if abs(offsetVert) > safeDistance - nullZone or abs(offsetLateral) > safeDistance - nullZone {
         // We are at a "safedistance" in at least one direction normal to the port.  Reset forward standoff to positive number.
            set standOffFore to safeDistance.
         } else if offsetFore < 0 { // 
         // Parallel to target port, but target port is behind us.  Navigate in box shape around target vessel.
            // Move Straight back to a safe distance, then move diagonally.
            set standOffFore to (offsetFore/abs(offsetFore))*safeDistance.
            if abs(offsetFore) > safeDistance - nullZone {
               set standOffVert to (offsetVert/abs(offsetVert))*safeDistance.
               set standOffLateral to (offsetLateral/abs(offsetLateral))*safeDistance.
            }
         }
         actuateControls().
         wait 0.
         return OP_CONTINUE.
      }
      
   }).
//========== End program sequence ===============================

}). //End of initializer delegate
