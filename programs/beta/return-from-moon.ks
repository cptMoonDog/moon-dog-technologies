@lazyglobal off.
// Program Template

local programName is "return-from-moon". //<------- put the name of the script here

// Header allowing for standalone operation.
//   If this program is to be used as part of a complete mission, run this script without parameters, and
//   then call the functions in the available_programs lexicon in the correct order of events for the mission
//   to build the MISSION_PLAN.
if not (defined available_programs) declare global available_programs is lexicon().
if not (defined kernel_ctl) runpath("0:/lib/core/kernel.ks"). 
if not (defined phys_lib) runpath("0:/lib/physics.ks"). 
if not (defined maneuver_ctl) runpath("0:/lib/maneuver_ctl.ks").

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
   declare parameter engineName.

//======== Local Variables =====

//=============== Begin program sequence Definition ===============================
   // The actual instructions implementing the program are in delegates, which the initializer adds to the MISSION_PLAN.
   // If you do not like anonymous functions, you could implement a named function elsewhere and add a reference
   // to it to the MISSION_PLAN instead, like so: kernel_ctl["MissionPlanAdd"](named_function@).
         kernel_ctl["MissionPlanAdd"]({
            clearscreen.
            local targetPeriapsis is 34000.
            local vinf is (ship:body:velocity:orbit - ship:body:body:velocity:orbit):mag - phys_lib["VatAlt"](ship:body:body, ship:body:altitude, phys_lib["sma"](ship:body:body, ship:body:orbit:apoapsis, targetPeriapsis)). //365. //Should be 373.789, Defines the velocity going into the other SOI, which determines some features of the new patch.
            print "vinf: "+vinf at(0, 1).

            local r0 is ship:altitude+ship:body:radius.
            local vejection is sqrt((r0*(ship:body:soiradius*vinf^2-2*ship:body:mu)+2*ship:body:soiradius*ship:body:mu)/(r0*ship:body:soiradius)). 
            local epsilon is (vejection^2)/2 - ship:body:mu/r0.
            local h is r0*(vejection)*sin(90). //vectorcross ship position and ship velocity
            local hecc is sqrt(1+(2*epsilon*(h^2))/(ship:body:mu^2)).
            local theta is arccos(1/hecc).
            
            local ejectionAngle is 180-theta. 
            //local ejectionAngle is 90+arcsin(1/hecc). //<-- This seems to be correct
            declare function angleToBodyPrograde {
               local bodyVelocity is ship:body:velocity:orbit - ship:body:body:velocity:orbit.
               local velPrograde is ship:velocity:orbit:mag*cos(vang(bodyVelocity, ship:velocity:orbit)).

               local angleToPrograde is (velPrograde/abs(velPrograde))*vang(bodyVelocity, up:forevector).
               if (velPrograde/abs(velPrograde)) < 0 set angleToPrograde to 360 + (velPrograde/abs(velPrograde))*vang(bodyVelocity, up:forevector).
               return angleToPrograde.
            }
            declare function angleToBodyRetro {
               local ang is angleToBodyPrograde()+180.
               if ang > 360 set ang to ang-360.
               return ang.
            }

            local diff is (angleToBodyRetro()-ejectionAngle).
            if diff < 0 set diff to diff + 360.
            local rateShip is 360/ship:orbit:period.
            local rateBody is 360/ship:body:orbit:period.

            local etaBurn is (diff)/(rateShip-rateBody).
            if ship:orbit:inclination > 90 set etaBurn to diff/(rateShip+rateBody).
            print "eta: "+etaBurn at(0, 15).

            add(node(time:seconds+etaBurn, 0, 0, vejection-ship:velocity:orbit:mag)).
            local lastpe is nextnode:orbit:nextpatch:periapsis+1.
            local lasteta is etaBurn.
            local starteta is etaBurn.
            local stepSize is 10.
            until nextnode:orbit:nextpatch:periapsis < targetPeriapsis+100 and nextnode:orbit:nextpatch:periapsis > targetPeriapsis-100 {
               if lastpe > nextnode:orbit:nextpatch:periapsis { //continue this way
                  set lastpe to nextnode:orbit:nextpatch:periapsis.
                  if lasteta > nextnode:eta {
                     set lasteta to nextnode:eta.
                     set nextnode:eta to nextnode:eta-stepSize.
                  } else {
                     set lasteta to nextnode:eta.
                     set nextnode:eta to nextnode:eta+stepSize.
                  }
                  print "top"+stepSize at(0, 2).
               } else if lastpe < nextnode:orbit:nextpatch:periapsis { //switch direction
                  if abs(lastpe - nextnode:orbit:nextpatch:periapsis) > 10 set stepSize to max(0.01, stepSize/10).
                  local lastlastpe is lastpe.
                  set lastpe to nextnode:orbit:nextpatch:periapsis.
                  if lasteta < nextnode:eta {
                     set nextnode:eta to nextnode:eta-stepSize.
                     set lasteta to nextnode:eta.
                  } else {
                     set nextnode:eta to nextnode:eta+stepSize.
                     set lasteta to nextnode:eta.
                  }
                  if lastlastpe < nextnode:orbit:nextpatch:periapsis and nextnode:orbit:nextpatch:periapsis > targetPeriapsis + 100 set nextnode:prograde to nextnode:prograde+stepSize. //break.
                  else if nextnode:orbit:nextpatch:periapsis < targetPeriapsis - 100 set nextnode:prograde to nextnode:prograde-stepSize.
                  print "not"+stepSize at(0, 2).
               }
            }
            print "etaError: "+(nextnode:eta-starteta) at(0, 11).
            print "error%: "+(100*(nextnode:eta-starteta)/ship:orbit:period) at(0, 12).
            print "errorDeg: "+((nextnode:eta-starteta)/ship:orbit:period)*360 at(0, 13).

//            until false {
//               print velocityat(ship, time:seconds+nextnode:orbit:nextpatcheta-10):orbit:mag at(0, 3).
//               print velocityat(ship, time:seconds+nextnode:orbit:nextpatcheta+10):orbit:mag at(0, 4).
//               print "ejectionangle: "+ejectionAngle at(0, 6).
//               print "angle to retro: "+ angleToBodyRetro() at(0, 9).
//               print ship:body:soiradius at(0, 10).
//               print nextnode:orbit:nextpatch:apoapsis at(0, 14).
//               print "mun alt: "+ship:body:altitude at(0, 15).
//               wait 0.0001.
//            }
            return OP_FINISHED.
         }).
   kernel_ctl["MissionPlanAdd"]({
      if ship:maxthrust > 1.01*maneuver_ctl["engineStat"](engineName, "thrust") {
         stage. 
      }
      maneuver_ctl["add_burn"]("node", engineName, "node", nextnode:deltav:mag).
      return OP_FINISHED.
   }).
   kernel_ctl["MissionPlanAdd"](maneuver_ctl["burn_monitor"]).

//========== End program sequence ===============================
   
}. //End of initializer delegate
