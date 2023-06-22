@lazyglobal off.
// Program Template

local programName is "approach". //<------- put the name of the script here

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
   if not (defined transfer_ctl) kernel_ctl["import-lib"]("lib/transfer_ctl").
   if not (defined maneuver_ctl) kernel_ctl["import-lib"]("lib/maneuver_ctl").
   
//======== Parameters used by the program ====
   // Don't forget to update the standalone system, above, if you change the number of parameters here.
   declare parameter argv.
   local engineName is "".
   local targetObject is "".
   if argv:split(" "):length > 1 {
      set engineName to argv:split(" ")[0].
      if not (maneuver_ctl["engineDef"](engineName)) return OP_FAIL.
      if argv:split(char(34)):length > 1 set targetObject to argv:split(char(34))[1]. // Quoted second parameter
      else set targetObject to argv:split(" ")[1].
      set kernel_ctl["output"] to "target: "+ targetObject.
   } else {
      set kernel_ctl["output"] to
         "Matches velocity with target vessel at closest approach."
         +char(10)+"Usage: add-program "+programName+" [ENGINE-NAME] [TARGET]".
      return.
   }

//======== Local Variables =====
   local dist is ship:position.
   local relVelocity is ship:velocity:orbit.
   local velToward is 0.  //speed toward target
   local timeOfClosest is time:seconds.
   local thrott is 0.

   declare function steeringVector {
      set relVelocity to (ship:velocity:orbit - target:velocity:orbit).
      set dist        to (target:position-ship:position).
      set velToward   to relVelocity:mag*cos(vang(relVelocity, dist)).  //speed toward target

      if relVelocity:mag > 30 or dist:mag < 150 return -1*relVelocity.
      else if relVelocity:mag < 1 return target:position.
      else {
         local nonClosingVel is vxcl(target:position, relVelocity).
         if nonClosingVel:mag > 1 return -vxcl(target:position, relVelocity):normalized. 
         else return -1*relVelocity:normalized.
      }
   }

   declare function throttleSetting {
      if dist:mag < 150 { // Within relativistic frame
         if vang(steeringVector(), ship:facing:forevector) > 5 return 0.
         if relVelocity:mag < 1 {
            return 0.
         } else if relVelocity:mag > 1 {
            local desiredSpeed is 5.
            local sensitivity is 10.

            local error is abs(relVelocity:mag).
            local sigmoid is error/sqrt((100-sensitivity)+error^2).
            return max(0, sigmoid).
         }
      } else if vang(steeringVector(), ship:facing:forevector) > 1 return 0.
      else if dist:mag < 5000 { // If you can't get within 5km of target...This is not the algorithm you are looking for.// Not close enough
         local error is vxcl(target:position, relVelocity):mag.
         if error > 1 {
            local sigmoid is error/sqrt(1+error^2).
            return max(0, sigmoid).
         } else return 0.
      } else return 0.
   }


//=============== Begin program sequence Definition ===============================
   // The actual instructions implementing the program are in delegates, Which the initializer adds to the MISSION_PLAN.
   // In this case, the first part of the program sequence
   // is given as an anonymous function, and the second part is a function implemented in the maneuver_ctl library. 
   // If you do not like anonymous functions, you could implement a named function elsewhere and add a reference
   // to it to the MISSION_PLAN instead, like so: kernel_ctl["MissionPlanAdd"](named_function@).

   
   // Programs should probably have at least 3 sections setup, program, and shutdown
      kernel_ctl["MissionPLanAdd"](programName, { // Find closest approach
         if not(hastarget) {
            set target to targetObject.
         }
         // Find approximate closest approach.
         local distanceAtTime is (ship:position - target:position):mag.
         local lastDistance is distanceAtTime.
         local t is time:seconds.
         local s is distanceAtTime/100. // Increment
         
         until lastDistance < distanceAtTime {
            set lastDistance to distanceAtTime.
            set s to distanceAtTime/1000.
            set t to t + s.
            set distanceAtTime to (positionat(ship, t)-positionat(target, t)):mag.
         }
         set timeOfClosest to t.

         lock steering to steeringVector().
         lock throttle to throttleSetting().
         return OP_FINISHED.
      }).
      kernel_ctl["MissionPLanAdd"](programName, { // Wait for closest approach and Kill velocity
         if time:seconds < timeOfClosest - 60 {
            set kernel_ctl["countdown"] to timeOfClosest - time:seconds.
            return OP_CONTINUE.
         } else if target:position:mag < 5000 {
            return OP_FINISHED.
         } else return OP_CONTINUE.
      }).
      kernel_ctl["MissionPlanAdd"](programName, {
         if dist:mag < 150 { // Within relativistic frame
            if relVelocity:mag < 1 {
               return OP_FINISHED.
            }
         }
         return OP_CONTINUE.
      }).
         
         
         
//========== End program sequence ===============================
   
}). //End of initializer delegate
