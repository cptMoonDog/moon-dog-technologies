@lazyglobal off.
// Program Template

local programName is "docking". //<------- put the name of the script here

// Header allowing for standalone operation.
//   If this program is to be used as part of a complete mission, run this script without parameters, and
//   then call the functions in the available_programs lexicon in the correct order of events for the mission
//   to build the MISSION_PLAN.
    // If you modify the number of parameters, be sure to fix the function call at the bottom of this file.
declare parameter p1 is "". 
//declare parameter p2 is "". 

if not (defined available_programs) declare global available_programs is lexicon().
if not (defined kernel_ctl) runpath("0:/lib/core/kernel.ks"). 

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
   
//======== Parameters used by the program ====
   // Don't forget to update the standalone system, above, if you change the number of parameters here.
   declare parameter notneeded is "".

//======== Local Variables =====

//=============== Begin program sequence Definition ===============================
   // The actual instructions implementing the program are in delegates, Which the initializer adds to the MISSION_PLAN.
   // In this case, the first part of the program sequence
   // is given as an anonymous function, and the second part is a function implemented in the maneuver_ctl library. 
   // If you do not like anonymous functions, you could implement a named function elsewhere and add a reference
   // to it to the MISSION_PLAN instead, like so: kernel_ctl["MissionPlanAdd"](named_function@).
   kernel_ctl["MissionPlanAdd"]({
      // Some inspiration from: https://www.reddit.com/r/Kos/comments/2n78zf/i_finally_did_it_automated_rendezvous_and_docking/
      if hastarget and not(target:istype("DockingPort")) {
         print "Select docking port." at(0, 3).
         lock steering to ship:prograde.

         return OP_CONTINUE.
      }
      
      if not (hastarget) {
         set ship:control:fore to 0.
         set ship:control:neutralize to true.
         RCS off.
         print "no target".
         return OP_FINISHED.
      }
      local port is ship:partsdubbed("dockingPort2")[0].
      lock steering to target:portfacing:vector:normalized*-1.
      wait until vang(port:portfacing:forevector, target:portfacing:vector:normalized*-1) < 0.5.
      local startTime is time:seconds.
      RCS on.
      local standOffFore is 100.
      local standOffVert is 0.
      local standOffLateral is 0.
      local nullzone is 0.5.
      until false {
         local dist is (target:position - port:position).
         local offsetVert is dist*port:portfacing:topvector.
         local offsetLateral is dist*port:portfacing:starvector.
         local offsetFore is dist*port:portfacing:forevector.
         local vel is (target:ship:velocity:orbit - ship:velocity:orbit).
         local speedVert is vel*port:portfacing:topvector.
         local speedLateral is vel*port:portfacing:starvector.
         local speedFore is vel*port:portfacing:forevector.

         print "speedFore: "+speedFore at(0, 5).
         print "offsetFore: "+offsetFore at(0, 6).

         print "speedLateral: "+speedLateral at(0, 8).
         print "offsetLateral: "+offsetLateral at(0, 9).

         print "speedVert: "+speedVert at(0, 11).
         print "offsetVert: "+offsetVert at(0, 12).
         
         print "dist: "+dist:mag at(0, 14).
         declare function getControlInputForAxis {
            parameter offset, speed, setpoint, nullZone.
            local speedLimit is 0.5.
            // If not in nullzone
            if offset < setpoint - nullZone or setpoint + nullZone < offset{
               local error is abs(offset-setpoint).
               local sigmoid is error/sqrt(1+error^2). 
               // Accelerate toward nullzone.
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
         local safeDistance is 25.
         if offsetVert > -0.5 and offsetVert < 0.5 and
            offsetLateral > -0.5 and offsetLateral < 0.5 and
            standOffFore > 1 and standOffFore > max(0, offsetFore - 1) {
            set standOffFore to standOffFore -1.
         } else { //Navigate in box shape around target vessel.
            if offsetFore < 0 {
               set standOffVert to (offsetVert/abs(offsetVert))*safeDistance.
               set standOffLateral to (offsetLateral/abs(offsetLateral))*safeDistance.
               set standOffFore to (offsetFore/abs(offsetFore))*safeDistance.
               set nullZone to 5.
            }
            if abs(offsetVert) > safeDistance-5 or abs(offsetLateral) > safeDistance-5 {
               set standOffFore to safeDistance.
            }
            if offsetFore > safeDistance-5 {
               set standOffVert to 0.
               set standOffLateral to 0.
            }
         }
         
         set ship:control:fore to getControlInputForAxis(offsetFore, speedFore, standOffFore, nullZone).
         set ship:control:top to getControlInputForAxis(offsetVert, speedVert, standOffVert, nullZone).
         set ship:control:starboard to getControlInputForAxis(offsetLateral, speedLateral, standOffLateral, nullZone).
         
         wait 0.25.
      }

      
   }).
//========== End program sequence ===============================
   
}. //End of initializer delegate
