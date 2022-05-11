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

declare function compassHeadingVector {
   declare parameter tgt.
   local northAngle is vang(vxcl(up:forevector, tgt), north:forevector).
   local eastAngle is vang(vxcl(up:forevector, tgt), north:starvector).
   local tgtheading is 0. //North.
   if northAngle < 90 and eastAngle < 90 { 
      return northAngle. //Northeast
   } else if northAngle < 90 and eastAngle > 90 { 
      return 360-northAngle. //Northwest
   } else if northAngle > 90 and eastAngle < 90 { 
      return northAngle. //Southeast
   } else if northAngle > 90 and eastAngle > 90 { 
      return 360-northAngle. //Southwest
   }
}

declare function compassVectorAdd {
   declare parameter dir.
   declare parameter axis.
   
   local difference is compassHeadingVector(axis) - compassHeadingVector(dir).
   set difference to difference/2.
   if difference < 0 return compassHeadingVector(axis) - difference.
   else return compassHeadingVector(dir) - difference.
} 

declare function compassReflectVectorAbout {
   declare parameter dir.
   declare parameter axis.
   
   local difference is compassHeadingVector(axis) - compassHeadingVector(dir).
   local reflection is compassHeadingVector(axis) + difference.
   if reflection >= 360 return reflection - 360.
   else return reflection.
} 

declare function RetrogradePitchAngle {
   if ship:altitude > 10000 return 90-vang(up:forevector, ship:retrograde:forevector).
   return 90-vang(up:forevector, ship:srfretrograde:forevector).
}
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
local tgt is latlng(10, -70).
lock tgtHeadingVector to vxcl(up:forevector, tgt:position).
lock spHeadingVector to vxcl(up:forevector, ship:srfprograde:forevector).
lock facingHeadingVector to vxcl(up:forevector, ship:facing:forevector).
lock steerHeadingDirection to angleaxis(vang(tgtHeadingVector, -spHeadingVector), up:forevector)*tgtHeadingVector:direction.
local tgtHeadingArrow is vecdraw(
                        v(0, 0, 0), 
                        {return tgtHeadingVector.},
                        RGB(1, 0, 0),
                        "Target Heading",
                        1,
                        true,
                        0.2,
                        true,
                        true).

local tgtArrow is vecdraw(
                        v(0, 0, 0), 
                        {return tgt:position.},
                        RGB(1, 1, 0),
                        "Target",
                        1,
                        true,
                        0.2,
                        true,
                        true).

local srfProArrow is vecdraw(
                        v(0, 0, 0), 
                        {return spHeadingVector*10.},
                        RGB(1, 0, 1),
                        "prograde Heading",
                        1,
                        true,
                        0.2,
                        true,
                        true).


//=============== Begin program sequence Definition ===============================
   // The actual instructions implementing the program are in delegates, Which the initializer adds to the MISSION_PLAN.
   // In this case, the first part of the program sequence
   // is given as an anonymous function, and the second part is a function implemented in the maneuver_ctl library. 
   // If you do not like anonymous functions, you could implement a named function elsewhere and add a reference
   // to it to the MISSION_PLAN instead, like so: kernel_ctl["MissionPlanAdd"](named_function@).
      kernel_ctl["MissionPlanAdd"]("landing", {
         // Orient orbit to target
         if abs(compassHeadingVector(ship:prograde:forevector) - compassHeadingVector(tgt:position)) > 0.25 and abs(ship:geoposition:lng - tgt:lng) > 100 {
            lock steering to heading(compassVectorAdd(ship:retrograde:forevector, tgt:position), RetrogradePitchAngle()).
            wait 5.
            lock throttle to 0.1.

            print "angle to target: "+abs(ship:geoposition:lng - tgt:lng) at(0, 2).
            print "heading angle: "+abs(compassHeadingVector(ship:srfprograde:forevector) - compassHeadingVector(tgt:position)) at(0, 3).
            print "distance: "+tgt:position:mag at(0, 4).
            return OP_CONTINUE.
         } else if abs(ship:geoposition:lng - tgt:lng) > 100 {
            lock throttle to 0. 
            return OP_CONTINUE.
         }
         //deorbit
         if ship:periapsis > 8000 {
            if not ship:orbit:hasnextpatch {
               if abs(ship:geoposition:lng - tgt:lng) > 90 and ship:periapsis > 5000 {
            print "angle to target: "+abs(ship:geoposition:lng - tgt:lng) at(0, 2).
            print "heading angle: "+abs(compassHeadingVector(ship:srfprograde:forevector) - compassHeadingVector(tgt:position)) at(0, 3).
            print "distance: "+tgt:position:mag at(0, 4).
                  //warpto(time:seconds+eta:apoapsis).
                  lock steering to ship:retrograde.
                  wait until vang(ship:facing:forevector, ship:retrograde:forevector) < 1.
                  lock throttle to 1.
                  return OP_CONTINUE.
               } else {
            print "angle to target: "+abs(ship:geoposition:lng - tgt:lng) at(0, 2).
            print "heading angle: "+abs(compassHeadingVector(ship:srfprograde:forevector) - compassHeadingVector(tgt:position)) at(0, 3).
            print "distance: "+tgt:position:mag at(0, 4).
                  lock throttle to 0.
                  return OP_CONTINUE.
               }
            } else { 
               lock steering to ship:retrograde.
               wait 10.
               until ship:periapsis < 1000 lock throttle to 1.
            }
            lock throttle to 0.
            return OP_CONTINUE.
         }
         //Landing point estimate:
         local spot is latlng(ship:geoposition:lat, ship:geoposition:lng+ship:groundspeed/(2*constant:pi*ship:body:radius)*10).

         local ttZeroH is ship:groundspeed/(ship:maxthrust/ship:mass). 
         local vertAccel is -(ship:body:mu/((ship:altitude+ship:body:radius)^2)). //negative is down.
         local ttImpact is (-ship:verticalspeed - sqrt(max(0, ship:verticalspeed^2 - 2*alt:radar*vertAccel)))/(vertAccel).
         clearscreen.
         print "ttzh: "+ttZeroH at(0, 10).
         print "tti: "+ttImpact at(0, 11).
         if vang(spHeadingVector, tgt:position) > 80 and ship:altitude > 10000 and ship:groundspeed > 10 {
            lock throttle to 1.
            return OP_CONTINUE.
         }
         if ttImpact > ttZeroH+30 and ship:altitude > 10000 {
            //set kuniverse:timewarp:warp to min(floor(ship:altitude/15000), kuniverse:timewarp:warp + 1).
            return OP_CONTINUE.
         } else {
            lock steering to vxcl(vcrs(steerHeadingDirection:forevector, up:forevector), ship:srfretrograde:forevector). //ship:retrograde.
            lock throttle to 0.
            if not (Kuniverse:timewarp:warp = 0) {
               set kuniverse:timewarp:warp to 0.
               //lock steering to ship:srfretrograde.
               //wait until vang(ship:facing:forevector, ship:srfretrograde:forevector) < 1.
            }else {
               //if alt:radar > 6 and ship:altitude < 50000 {
               if ship:altitude-spot:terrainheight > 6 and ship:altitude < 50000 {
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
                  print "terrain height: "+ship:geoposition:terrainheight at(0, 17).
                  print "spot height: "+spot:terrainheight at(0,18).

                  if ship:verticalspeed > -10 and ship:verticalspeed < 0 or ship:verticalspeed > 10 lock steering to ship:srfretrograde.
                  else lock steering to vxcl(vcrs(steerHeadingDirection:forevector, up:forevector), ship:srfretrograde:forevector). //ship:retrograde.
                  //else lock steering to up:forevector*angleaxis(pitchangle, ship:srfretrograde:starvector).//min(pitchLimit, max(0,pitchAngle))

                  local throttMargin is 0.1.
                  if ship:verticalspeed > -2 set thrott to 0.
                  //else set thrott to throttMargin*ttImpact/min(ttZeroSrf-ttImpact, throttMargin*ttImpact).
                  else if ttImpact-3 < ttZeroSrf set thrott to min(1, thrott + 0.01).
                  else set thrott to max(0, thrott - 0.01).
                  lock throttle to thrott.

                  //local throttPV is ship:verticalspeed*ship:velocity:surface:mag/alt:radar.
                  //if ship:velocity:surface:mag < 100 or alt:radar > 8500 lock throttle to -(throttPV/sqrt(1+throttPV^2)).
                  //else lock throttle to 1.
                  //if alt:radar < 25 {
                  if ship:altitude-spot:terrainheight < 25 {
                     gear on.
                     if ship:velocity:surface:mag > 100 kuniverse:reverttolaunch().
                  }
                  return OP_CONTINUE.
               } else if ship:altitude-spot:terrainheight < 6 {
                  lock throttle to 0.
                  lock steering to up.
                  return OP_FINISHED.
               }
            }
         }
      }).
//========== End program sequence ===============================
   
}. //End of initializer delegate
