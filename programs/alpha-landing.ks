@lazyglobal off.
// Program Template

local programName is "alpha-landing". //<------- put the name of the script here

// Header allowing for standalone operation.
//   If this program is to be used as part of a complete mission, run this script without parameters, and
//   then call the functions in the available_programs lexicon in the correct order of events for the mission
//   to build the MISSION_PLAN.
if not (defined kernel_ctl) runpath("0:/lib/core/kernel.ks"). 

declare function compassHeadingFromVector {
   declare parameter targetVector.
   local northAngle is vang(vxcl(up:forevector, targetVector), north:forevector).
   local eastAngle is vang(vxcl(up:forevector, targetVector), vcrs(up:forevector, north:forevector)).
   local tgtheading is 0. //North.
   print "nortangle: "+northAngle at(0, 5).
   print "eastAngle: "+eastAngle at(0, 6).
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
   
   local difference is compassHeadingFromVector(axis) - compassHeadingFromVector(dir).
   set difference to difference/2.
   if difference < 0 return compassHeadingFromVector(axis) - difference.
   else return compassHeadingFromVector(dir) - difference.
} 

declare function compassHeadingFromVectorReflectionAbout {
   declare parameter dir.
   declare parameter axis.
   
   local difference is compassHeadingFromVector(axis) - compassHeadingFromVector(dir).
   local reflection is compassHeadingFromVector(axis) + difference.
   if reflection >= 360 return reflection - 360.
   else return reflection.
} 

declare function RetrogradePitchAngle {
   if ship:altitude > 10000 return 90-vang(up:forevector, ship:retrograde:forevector).
   return 90-vang(up:forevector, ship:srfretrograde:forevector).
}

//Add initialzer for this program sequence to the lexicon of available programs
// Could be written as available_programs:add...but that occasionally produces an error when run as a standalone script.
kernel_ctl["availablePrograms"]:add(programName, {
   declare parameter argv.
   local lat is "".
   local lng is "".

   if argv:split(" "):length = 2 {
      set lat to argv:split(" ")[0]:tonumber(-1000).
      set lng to argv:split(" ")[1]:tonumber(-1000).
      if lat = -1000 or lng = -1000 {
         set kernel_ctl["output"] to
            "Attempts to land at the given coordinates"
            +char(10)+"Usage: add alpha-landing [LATITUDE] [LONGITUDE]".
         return.
      }
   } else {
      set kernel_ctl["output"] to
         argv+"Attempts to land at the given coordinates"
         +char(10)+"Usage: add alpha-landing [LATITUDE] [LONGITUDE]".
      return.
   }
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
      local vSpeedPID is pidloop(1, 0, 0, 0, 1).
      local hSpeedPID is pidloop(1, 0, 0, 0, 1).
      local pitchPID is pidloop(1, 0, 0, -90, 0).
      local yawPID is pidloop(1, 0, 0, -90, 90).
      local tgt is latlng(lat, lng).
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

      local steerArrow is vecdraw(
                        v(0, 0, 0), 
                        {return spHeadingVector*10.},
                        RGB(1, 1, 1),
                        "steering",
                        1,
                        true,
                        0.2,
                        true,
                        true).


//=============== Begin program sequence Definition ===============================
      // Assumes spacecraft is already on a low over flight trajectory.
      kernel_ctl["MissionPlanAdd"](programName, {
         // Orient orbit to target
         //Landing point estimate:
         local velDegrees is ship:groundspeed*(180/(constant:pi*ship:body:radius)).
         local test1 is sin(ship:geoposition:lat)*sin(tgt:lat).
         local test2 is cos(ship:geoposition:lng)*cos(tgt:lng)*cos(abs(ship:geoposition:lng - tgt:lng)).
         local ttTarget is max(
           tgt:position:mag/ship:groundspeed,
           arccos(min(1, test1 + test2))/velDegrees
         ).
         local waiting is true.
         local ttZeroTotal is ship:velocity:surface:mag/(ship:maxthrust/ship:mass).
         local ttZeroH is ship:groundspeed/((ship:maxthrust/ship:mass)*cos(vang(-ship:facing:forevector, vxcl(up:forevector, -ship:facing:forevector)))). 
         local ttZeroV is -ship:verticalspeed/((ship:maxthrust/ship:mass)*sin(vang(-ship:facing:forevector, vxcl(up:forevector, -ship:facing:forevector)))). 
         local vertAccel is -(ship:body:mu/((ship:altitude+ship:body:radius)^2)). //negative is down.
         local ttImpact is (-ship:verticalspeed - sqrt(max(0, ship:verticalspeed^2 - 2*(ship:altitude-tgt:terrainheight)*vertAccel)))/vertAccel.
         set ttImpact to ttImpact + sin(velDegrees*ttImpact)*ttImpact.

         clearscreen.
         local tgtDescentRate is -((ship:altitude-tgt:terrainheight)/(ttTarget)) - vertAccel*ttTarget/4.
         print "Target Descent rate: "+tgtDescentRate at(0, 10).
         print "ttTarget: "+ttTarget at(0, 11).
         print "tti: "+ttImpact at(0, 12).
         print "ttZero: "+ttZeroTotal at(0, 13).
         local ttzhError is ttTarget - ttZeroH.
         local vSpeedError is max(0, min(0, tgtDescentRate) - ship:verticalspeed).
         //local vSpeedError is -(alt:radar/(ttTarget)) - ship:verticalspeed.
         //local vSpeedError is abs(ship:verticalspeed) - abs(targetVSpeed).
         //local ttImpactError is max(0, choose max(ttZeroH - ttTarget, ttImpact - ttTarget) if ttZeroH > ttZeroV else max(ttZeroV - ttTarget, ttZeroV - ttImpact)).
         local ttImpactError is 5*(ttZeroTotal - ttTarget)/ttTarget + (ttTarget - ttImpact)/(ttTarget^2) + (ttZeroTotal - ttImpact)/(ttTarget^2).
         local ttImpactSigmoid is max(0, ttImpactError/sqrt(1+ttImpactError^2)).
         lock throttle to ttImpactSigmoid.
         //local ttSigmoid is max(0, ttzhError/sqrt(1+ttzhError^2)).
         local vSpeedSigmoid is vSpeedError/sqrt(10+vSpeedError^2).
         print "ttzhError: "+ttzhError at(0, 15).
         print "vSpeedError: "+vSpeedError at(0, 16).
         print "ttImpactError: "+ttImpactError at(0, 17).
         //print "ttSigmoid: "+ttSigmoid at(0, 17).
         print "vSpeedSigmoid: "+vSpeedSigmoid at(0, 18).
         print "tgt compass: "+compassHeadingFromVector(tgt:position) at(0, 19).
         print "prograde compass: "+compassHeadingFromVector(ship:srfprograde:forevector) at(0, 20).
         // Pitch up to maintain descent rate
         lock steering to ship:srfretrograde:forevector*angleAxis(
           //Amount of pitch
           max(-vSpeedSigmoid*vang(ship:srfretrograde:forevector, up:forevector), -vang(ship:srfretrograde:forevector, up:forevector)), 
           //max(-vSpeedSigmoid*vang(ship:srfretrograde:forevector, up:forevector), -vang(ship:srfretrograde:forevector, up:forevector)), 
           //Axis
           vcrs(up:forevector, ship:srfretrograde:forevector)
         )* angleAxis(
            //Amount of steering
            choose (compassHeadingFromVector(ship:srfprograde:forevector) - compassHeadingFromVector(tgt:position))*3 if alt:radar > 1000 else 0, 
            //axis
            up:forevector
         ).
         if(ttTarget < ttZeroTotal) {
           set waiting to false.
         } 
         if waiting return OP_CONTINUE.
         if alt:radar < 50 gear on.
         if abs(alt:radar) < 5 or ship:status = "LANDED" {
            lock throttle to 0.
            return OP_FINISHED.
         } 
         return OP_CONTINUE.
      }).
//========== End program sequence ===============================
   
}). //End of initializer delegate
