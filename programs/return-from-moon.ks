@lazyglobal off.
// Program Template

local programName is "return-from-moon". //<------- put the name of the script here

// Header allowing for standalone operation.
//   If this program is to be used as part of a complete mission, run this script without parameters, and
//   then call the functions in the available_programs lexicon in the correct order of events for the mission
//   to build the MISSION_PLAN.
declare parameter p1 is "". 
declare parameter p2 is "". 
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

//======== Local Variables =====

//=============== Begin program sequence Definition ===============================
   // The actual instructions implementing the program are in delegates, which the initializer adds to the MISSION_PLAN.
   // If you do not like anonymous functions, you could implement a named function elsewhere and add a reference
   // to it to the MISSION_PLAN instead, like so: MISSION_PLAN:add(named_function@).
         MISSION_PLAN:add({
            clearscreen.
            local vinf is 384. //Defines the velocity going into the other SOI, which determines some features of the new patch.
            local adjForSoi is (1-(ship:body:soiradius)/((ship:body:altitude+ship:body:body:radius)-(ship:body:soiradius))).
            //set vinf to vinf*0.885.

            local r0 is ship:altitude+ship:body:radius.
            local vejection is sqrt((r0*(ship:body:soiradius*vinf^2-2*ship:body:mu)+2*ship:body:soiradius*ship:body:mu)/(r0*ship:body:soiradius)). 
            local hsma is -ship:body:mu/max(0.0001, vejection^2).
            local focaldist is r0+abs(hsma).
            local epsilon is ((vejection)^2)/2 - ship:body:mu/r0.
            local h is r0*(vejection).
            local hecc is sqrt(1+(2*epsilon*h^2)/(ship:body:mu^2)).
            local ejectionAngle is 180-arcsin(1/hecc).
            local angleToBodyPrograde is (vang(ship:body:velocity:orbit-ship:body:body:velocity:orbit, vxcl(north:forevector, up:forevector))).
            if (ship:position-ship:body:body:position):mag < ship:body:altitude+ship:body:body:radius set angleToBodyPrograde to 360-angleToBodyPrograde.
            local angleToBodyRetro is angleToBodyPrograde+180.
            if angleToBodyRetro > 360 set angleToBodyRetro to angleToBodyRetro-360.

            set ejectionangle to ejectionangle*adjForSoi.
            print "adj: "+adjforSoi at(0, 5).

            local diff is 1*(angleToBodyRetro-ejectionAngle).
            print "diffstart: "+diff at(0, 7).
            if diff < 0 set diff to diff + 360.
            print "diffadj: "+diff at(0, 8).
            local rateShip is 360/ship:orbit:period.
            local rateBody is 360/ship:body:orbit:period.

            local etaBurn is (diff)/(rateShip-rateBody).

            add(node(time:seconds+etaBurn, 0, 0, vejection-ship:velocity:orbit:mag)).
            print velocityat(ship, time:seconds+nextnode:orbit:nextpatcheta-10):orbit:mag at(0, 3).
            print velocityat(ship, time:seconds+nextnode:orbit:nextpatcheta+10):orbit:mag at(0, 4).
            local lastpe is nextnode:orbit:nextpatch:periapsis+1.
            local lasteta is etaBurn.
            local starteta is etaBurn.
            local stepSize is 5.
            until nextnode:orbit:nextpatch:periapsis < 40000 and nextnode:orbit:nextpatch:periapsis > 34000 {
               if lastpe > nextnode:orbit:nextpatch:periapsis { //continue this way
                  set lastpe to nextnode:orbit:nextpatch:periapsis.
                  if lasteta > nextnode:eta {
                     set lasteta to nextnode:eta.
                     set nextnode:eta to nextnode:eta-stepSize.
                  } else {
                     set lasteta to nextnode:eta.
                     set nextnode:eta to nextnode:eta+stepSize.
                  }
                  print "top" at(0, 2).
               } else if lastpe < nextnode:orbit:nextpatch:periapsis { //switch direction
                  local lastlastpe is lastpe.
                  set lastpe to nextnode:orbit:nextpatch:periapsis.
                  if lasteta < nextnode:eta {
                     set nextnode:eta to nextnode:eta-stepSize.
                     set lasteta to nextnode:eta.
                  } else {
                     set nextnode:eta to nextnode:eta+stepSize.
                     set lasteta to nextnode:eta.
                  }
                  if lastlastpe < nextnode:orbit:nextpatch:periapsis and nextnode:orbit:nextpatch:periapsis > 34000 set nextnode:prograde to nextnode:prograde+1. //break.
                  else if nextnode:orbit:nextpatch:periapsis < 34000 set nextnode:prograde to nextnode:prograde-1.
                  print "not" at(0, 2).
               }
            }

            print "ejectionangle: "+ejectionAngle at(0, 6).
            print "angle to retro: "+ angletobodyretro at(0, 9).
            print ship:body:soiradius at(0, 10).
            print "etaError: "+(nextnode:eta-starteta) at(0, 11).
            print "error%: "+(100*(nextnode:eta-starteta)/ship:orbit:period) at(0, 12).
            print nextnode:orbit:nextpatch:apoapsis at(0, 13).
            print "mun alt: "+ship:body:altitude at(0, 14).
            wait 0.0001.
            return OP_FINISHED.
         }).

//========== End program sequence ===============================
   
}. //End of initializer delegate

// If run standalone, initialize the MISSION_PLAN and run it.
if p1 {
   available_programs[programName]().
   kernel_ctl["start"]().
   shutdown.
} 
