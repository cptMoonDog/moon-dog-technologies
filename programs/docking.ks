@lazyglobal off.
// Program Template

local programName is "docking". //<------- put the name of the script here

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
   declare parameter notneeded is "".

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
      if not(hastarget) or (hastarget and not(target:istype("DockingPort"))) {
         return ship:prograde.
      } else target:portfacing:vector:normalized*-1.
   }

   local ports is 0.
   local port is 0.
   local startTime is time:seconds.
   local standOffFore is 100. // Don't approach closer than 100m until aligned.
   local standOffVert is 0.
   local standOffLateral is 0.
   local nullZone is 0.5.

   local dist is (target:position - port:position).

   local offsetVert is dist*port:portfacing:topvector.
   local offsetLateral is dist*port:portfacing:starvector.
   local offsetFore is dist*port:portfacing:forevector.

   local vel is (target:ship:velocity:orbit - ship:velocity:orbit).

   local speedVert is vel*port:portfacing:topvector.
   local speedLateral is vel*port:portfacing:starvector.
   local speedFore is vel*port:portfacing:forevector.

   local safeDistance is 25.
   
   declare function updateVectors {
      set dist          to (target:position - port:position).

      set offsetVert    to dist*port:portfacing:topvector.
      set offsetLateral to dist*port:portfacing:starvector.
      set offsetFore    to dist*port:portfacing:forevector.

      set vel           to (target:ship:velocity:orbit - ship:velocity:orbit).

      set speedVert     to vel*port:portfacing:topvector.
      set speedLateral  to vel*port:portfacing:starvector.
      set speedFore     to vel*port:portfacing:forevector.
   }


//=============== Begin program sequence Definition ===============================
   // The actual instructions implementing the program are in delegates, Which the initializer adds to the MISSION_PLAN.
   // In this case, the first part of the program sequence
   // is given as an anonymous function, and the second part is a function implemented in the maneuver_ctl library. 
   // If you do not like anonymous functions, you could implement a named function elsewhere and add a reference
   // to it to the MISSION_PLAN instead, like so: kernel_ctl["MissionPlanAdd"](named_function@).
   kernel_ctl["MissionPlanAdd"]("docking", {
      // Some inspiration from: https://www.reddit.com/r/Kos/comments/2n78zf/i_finally_did_it_automated_rendezvous_and_docking/

      // Collect info about this vessel
      if not(ports) {
         list DockingPorts in ports.
         if ports:length = 0 {
            print "No Docking ports on this vessel.".
            return OP_FINISHED.
         }
         port is ports[0].
         lock steering to steeringVector.
      } 
      // Verify that we have a valid target.
      if not(hastarget) or (hastarget and not(target:istype("DockingPort"))) {
         print "Select docking port." at(0, 3).
         return OP_CONTINUE.
      } 
      updateVectors().
      // Wait until port is aligned with target port.
      if vang(port:portfacing:forevector, target:portfacing:vector:normalized*-1) > 0.5 return OP_CONTINUE.
      else if not RCS {
         set startTime to time:seconds.
         RCS on.
         lock ship:control:fore      to getControlInputForAxis(offsetFore, speedFore, standOffFore, nullZone).
         lock ship:control:top       to getControlInputForAxis(offsetVert, speedVert, standOffVert, nullZone).
         lock ship:control:starboard to getControlInputForAxis(offsetLateral, speedLateral, standOffLateral, nullZone).
      }

      print "speedFore: "+speedFore at(0, 5).
      print "offsetFore: "+offsetFore at(0, 6).

      print "speedLateral: "+speedLateral at(0, 8).
      print "offsetLateral: "+offsetLateral at(0, 9).

      print "speedVert: "+speedVert at(0, 11).
      print "offsetVert: "+offsetVert at(0, 12).
      
      print "dist: "+dist:mag at(0, 14).
      // If aligned with target port, and standoff distance is not negative (occupying same space as target) move closer.
      if (offsetVert > -nullZone and offsetVert < nullZone) and
         (offsetLateral > -nullZone and offsetLateral < nullZone) and
         standOffFore > 1 and standOffFore > max(0, offsetFore - 1) {
         set standOffFore to standOffFore -1.
      } else { 
         // Parallel to target port, but target port is behind us.  Navigate in box shape around target vessel.
         if offsetFore < 0 { // 
            // Move off to a safe distance, in the same direction as all current offsets (away).
            set standOffVert to (offsetVert/abs(offsetVert))*safeDistance.
            set standOffLateral to (offsetLateral/abs(offsetLateral))*safeDistance.
            set standOffFore to (offsetFore/abs(offsetFore))*safeDistance.
            set nullZone to 5. // Relax nullZone, because do not need precision when far from target.
         }
         // We are at a "safedistance" in at least one direction normal to the port.  Reset forward standoff
         if abs(offsetVert) > safeDistance-5 or abs(offsetLateral) > safeDistance-5 {
            set standOffFore to safeDistance.
         }
         // We are at a "safedistance" in the forward direction.  Move into alignment with target port.
         if offsetFore > safeDistance-5 {
            set standOffVert to 0.
            set standOffLateral to 0.
         }
      }
      
      wait 0.
      return OP_CONTINUE.
   }).
//========== End program sequence ===============================
   
}). //End of initializer delegate
