@lazyglobal off.
// Program Template

local programName is "munar-ascent". //<------- put the name of the script here

// Header allowing for standalone operation.
//   If this program is to be used as part of a complete mission, run this script without parameters, and
//   then call the functions in the available_programs lexicon in the correct order of events for the mission
//   to build the MISSION_PLAN.
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
   if not (defined maneuver_ctl) runpath("0:/lib/maneuver_ctl.ks").
   
//======== Parameters used by the program ====
   // Don't forget to update the standalone system, above, if you change the number of parameters here.

//======== Local Variables =====
         local start is 0.
         local h is 90.
         local p is 90.
         local lastAlt is 0.
         local lastTime is time:seconds.

//=============== Begin program sequence Definition ===============================
   // The actual instructions implementing the program are in delegates, Which the initializer adds to the MISSION_PLAN.
   // In this case, the first part of the program sequence
   // is given as an anonymous function, and the second part is a function implemented in the maneuver_ctl library. 
   // If you do not like anonymous functions, you could implement a named function elsewhere and add a reference
   // to it to the MISSION_PLAN instead, like so: MISSION_PLAN:add(named_function@).
         MISSION_PLAN:add({
            if start=0 set start to time:seconds.
            if time:seconds < start + 10 return OP_CONTINUE.
            if ship:apoapsis < 20000 {
               lock throttle to 1.
               lock steering to heading(h, p).
               if ship:altitude < 8500 {
                  local dAlt is (alt:radar-lastAlt)/(time:seconds-lastTime).
                  if dAlt < 0 or ship:verticalspeed < 10 set p to min(90, p + 0.5).
                  else set p to max(0, p - 0.5).
               } else if ship:verticalspeed < 10 and ship:periapsis < 0 set p to min(90, p + 0.5). 
               else set p to max(0, p - 0.5).
               set lastAlt to alt:radar.
               return OP_CONTINUE.
            } else {
               set throttle to 0.
               set start to 0.
               return OP_FINISHED.
            }
         }).
         MISSION_PLAN:add({
            maneuver_ctl["add_burn"]("prograde", "terrier", "ap", "circularize").
            return OP_FINISHED.
         }).
         MISSION_PLAN:add(maneuver_ctl["burn_monitor"]).
//========== End program sequence ===============================
   
}. //End of initializer delegate

// If run standalone, initialize the MISSION_PLAN and run it.
if p1 {
   available_programs[programName](p1).
   kernel_ctl["start"]().
} 
