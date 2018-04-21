@lazyglobal off.
// Program Template

local programName is "landing". //<------- put the name of the script here

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
   if not (defined transfer_ctl) runpath("0:/lib/transfer_ctl.ks").
   if not (defined maneuver_ctl) runpath("0:/lib/maneuver_ctl.ks").
   
//======== Parameters used by the program ====
   // Don't forget to update the standalone system, above, if you change the number of parameters here.

//======== Local Variables =====
      local pitchangle is 90-vang(up:forevector, ship:srfprograde:forevector).
      local thrott is 0.

//=============== Begin program sequence Definition ===============================
   // The actual instructions implementing the program are in delegates, Which the initializer adds to the MISSION_PLAN.
   // In this case, the first part of the program sequence
   // is given as an anonymous function, and the second part is a function implemented in the maneuver_ctl library. 
   // If you do not like anonymous functions, you could implement a named function elsewhere and add a reference
   // to it to the MISSION_PLAN instead, like so: MISSION_PLAN:add(named_function@).
      MISSION_PLAN:add({
        print "WARNING WARNING WARNING".
        print "Work in progress.  Do not expect your pilot to survive if you use this".
        print "WARNING WARNING WARNING".
         //deorbit
         if ship:periapsis > 10000 {
            if not ship:orbit:hasnextpatch {
               warpto(time:seconds+eta:apoapsis).
               lock steering to ship:retrograde.
               wait until vang(ship:facing:forevector, ship:retrograde:forevector) < 1.
               until ship:periapsis < -1000 lock throttle to 1.
            } else { 
               lock steering to ship:retrograde.
               wait 10.
               until ship:periapsis < 1000 lock throttle to 1.
            }
            lock throttle to 0.
            return OP_CONTINUE.
         }
         local ttZeroH is ship:groundspeed/(ship:maxthrust/ship:mass). 
         local vertAccel is -(ship:body:mu/((ship:altitude+ship:body:radius)^2)). //negative is down.
         local ttImpact is (-ship:verticalspeed - sqrt(max(0, ship:verticalspeed^2 - 2*alt:radar*vertAccel)))/(vertAccel).
         clearscreen.
         print "ttzh: "+ttZeroH at(0, 10).
         print "tti: "+ttImpact at(0, 11).
         if ttImpact > ttZeroH+30 and ship:altitude > 10000 {
            set kuniverse:timewarp:warp to min(floor(ship:altitude/15000), kuniverse:timewarp:warp + 1).
            return OP_CONTINUE.
         } else {
            if not (Kuniverse:timewarp:warp = 0) {
               set kuniverse:timewarp:warp to 0.
               lock steering to ship:srfretrograde.
               lock throttle to 0.
               wait until vang(ship:facing:forevector, ship:srfretrograde:forevector) < 1.
            }else {
               if alt:radar > 6 and ship:altitude < 50000 {
                  local pitchLimit is vang(up:forevector, ship:srfretrograde:forevector).
                  local ttZeroV is max(0, ship:verticalspeed/(ship:body:mu/((ship:altitude+ship:body:radius)^2)-ship:maxthrust/ship:mass)). //Assuming full thrust straight up.
                  local ttZeroSrf is ship:velocity:surface:mag/(ship:maxthrust/ship:mass).
                  local pitchMin is min(pitchLimit, (-ship:verticalspeed/ship:velocity:surface:mag)*90).
                  if ttImpact-8 < ttZeroV set pitchangle to max(pitchMin, pitchangle-0.5).
                  else set pitchangle to min(pitchLimit, pitchangle+0.5).
                  print "ttzv: "+ttzeroV at(0, 12).
                  print "ttz: "+ttzeroSrf at(0, 13).
                  print "pitch: "+pitchangle at(0, 14).
                  print "pitchLimit: "+pitchLimit at(0, 15).
                  print "pitchMin: "+pitchMin at(0, 16).

                  if ship:verticalspeed > -10 and ship:verticalspeed < 0 or ship:verticalspeed > 10 lock steering to ship:srfretrograde.
                  else lock steering to up:forevector*angleaxis(pitchangle, ship:srfretrograde:starvector).//min(pitchLimit, max(0,pitchAngle))

                  if ship:verticalspeed > -2 set thrott to 0.
                  else if ttImpact-3 < ttZeroSrf set thrott to min(1, thrott + 0.01).
                  else set thrott to max(0, thrott - 0.01).
                  lock throttle to thrott.

                  //local throttPV is ship:verticalspeed*ship:velocity:surface:mag/alt:radar.
                  //if ship:velocity:surface:mag < 100 or alt:radar > 8500 lock throttle to -(throttPV/sqrt(1+throttPV^2)).
                  //else lock throttle to 1.
                  if alt:radar < 25 {
                     gear on.
                     if ship:velocity:surface:mag > 100 kuniverse:reverttolaunch().
                  }
                  return OP_CONTINUE.
               } else if alt:radar < 6 {
                  lock throttle to 0.
                  lock steering to up.
                  return OP_FINISHED.
               }
            }
         }
      }).
//========== End program sequence ===============================
   
}. //End of initializer delegate

// If run standalone, initialize the MISSION_PLAN and run it.
if p1 {
   available_programs[programName](p1).
   kernel_ctl["start"]().
   shutdown.
} 
