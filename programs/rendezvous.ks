@lazyglobal off.
// Program Template

local programName is "rendezvous". //<------- put the name of the script here
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
         "Creates a rendezvous with a ship or object in a coplanar orbit."
         +char(10)+"Usage: add rendezvous [ENGINE-NAME] [TARGET]".
      return.
   }

//======== Local Variables =====
   local dist is ship:position.
   local relVelocity is ship:velocity:orbit.
   local velToward is 0.  //speed toward target
   local timeStart is time:seconds.
   local thrott is 0.

   local missDistance is 0.

   local stopDistance is 150.
   local stopVelocity is 0.5.

   declare function steeringVector {
      set relVelocity to (ship:velocity:orbit - target:velocity:orbit).
      set dist        to (target:position-ship:position).

      set missDistance to vdot(dist, relVelocity:normalized)*tan(vang(dist, relVelocity)).

      if dist:mag > stopDistance {
         if missDistance > stopDistance return -vxcl(target:position, relVelocity):normalized. 
         else if missDistance < stopDistance*0.75 return vxcl(target:position, relVelocity):normalized. 
         else return -1*relVelocity:normalized.
      } else {
         return -1*relVelocity:normalized.
      }
   }

   declare function throttleSetting {
      set relVelocity to (ship:velocity:orbit - target:velocity:orbit).
      set missDistance to relVelocity:normalized*dist:mag*tan(vang(dist, relVelocity)).
      set dist        to (target:position-ship:position).
      if vang(steeringVector(), ship:facing:forevector) > 1 return 0.
      // Safety First
      if dist:mag < 1000 { // Within relativistic frame
         if dist:mag < stopDistance {
            if relVelocity:mag < stopVelocity {
               return 0.
            } else if relVelocity:mag > stopVelocity {

               local error is abs(relVelocity:mag).
               local sigmoid is error/sqrt(1+error^2).
               return max(0, sigmoid).
            }
         } else {
            local desiredSpeed is dist:mag/10.

            local error is max(0, relVelocity:mag-desiredSpeed).
            local sigmoid is error/sqrt(1+error^2).
            return max(0, sigmoid).
         }
      } 
      // Heading needs to catch up to steering.  DO NOT fire
      else if dist:mag < 10000 { // If you can't get within 10km of target...This is not the algorithm you are looking for.// Not close enough
         local error is max(0, missDistance-stopDistance). //vxcl(target:position, relVelocity):mag.
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

   
      kernel_ctl["MissionPlanAdd"](programName, {
         set target to targetObject.
         if not hastarget return OP_FAIL.
         // Originally made with targets in higher orbits in mind.
         if target:orbit:apoapsis < 1.01*ship:orbit:apoapsis and target:orbit:apoapsis > 0.99*ship:orbit:apoapsis return OP_FINISHED. // 
         if not (hasnode) {
            local mnvr is node(transfer_ctl["etaPhaseAngle"]()+time:seconds, 0,0, transfer_ctl["dv"](ship:body, target)).
            add(mnvr).
            maneuver_ctl["add_burn"]("node", engineName, "node", mnvr:deltav:mag).
            return OP_FINISHED.
         }
         print "Maneuver creation failed.".
         return OP_FAIL.
      }).
      kernel_ctl["MissionPlanAdd"](programName, maneuver_ctl["burn_monitor"]).
      kernel_ctl["MissionPlanAdd"](programName, {
         set kernel_ctl["status"] to "Set start time".
         set timeStart to time:seconds. 
         return OP_FINISHED.
      }).
   
      kernel_ctl["MissionPlanAdd"](programName, {
         set kernel_ctl["status"] to "waiting for 10k"+time:seconds.
         if (ship:position - target:position):mag < 10000 {
            lock steering to steeringVector().
            lock throttle to throttleSetting().
            return OP_FINISHED.
         } else if time:seconds > timeStart + ship:orbit:period return OP_FAIL.
         else return OP_CONTINUE.
      }).

      kernel_ctl["MissionPlanAdd"](programName, {
         set kernel_ctl["status"] to "Target Distance: "+dist:mag.
         if dist:mag < 200 { // Within relativistic frame
            if relVelocity:mag < 0.5 {
               return OP_FINISHED.
            }
         }
         return OP_CONTINUE.
      }).
         
         
//========== End program sequence ===============================
   
}). //End of initializer delegate
