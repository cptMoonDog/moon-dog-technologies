@lazyglobal off.
// Program Template

local programName is "alpha-landing". //<------- put the name of the script here

// Header allowing for standalone operation.
//   If this program is to be used as part of a complete mission, run this script without parameters, and
//   then call the functions in the available_programs lexicon in the correct order of events for the mission
//   to build the MISSION_PLAN.
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
         local spot is latlng(ship:geoposition:lat, ship:geoposition:lng+ship:groundspeed/(2*constant:pi*ship:body:radius)*10).

         local ttZeroH is ship:groundspeed/((ship:maxthrust/ship:mass)*cos(vang(ship:srfprograde:forevector, vxcl(up:forevector, ship:srfprograde:forevector)))). 
         local ttZeroV is -ship:verticalspeed/((ship:maxthrust/ship:mass)*sin(vang(ship:srfprograde:forevector, vxcl(up:forevector, ship:srfprograde:forevector)))). 
         local vertAccel is -(ship:body:mu/((ship:altitude+ship:body:radius)^2)). //negative is down.
         local ttImpact is (-ship:verticalspeed - sqrt(max(0, ship:verticalspeed^2 - 2*alt:radar*vertAccel)))/(vertAccel).
         local ttTarget is tgt:position*ship:srfprograde:forevector/ship:groundspeed.
         clearscreen.
         print "ttzh: "+ttZeroH at(0, 10).
         print "ttTarget: "+ttTarget at(0, 11).
         print "tti: "+ttImpact at(0, 12).
         print "ttVZero: "+ttZeroV at(0, 13).
         local ttzhError is ttZeroH - ttTarget.
         local vSpeedError is ttZeroV - ttImpact.
         //local vSpeedError is abs(ship:verticalspeed) - abs(targetVSpeed).
         local ttImpactError is max(ttImpact - ttTarget, ttZeroV-ttImpact).
         local ttImpactSigmoid is max(0, ttImpactError/sqrt(1+ttImpactError^2)).
         //local ttSigmoid is max(0, ttzhError/sqrt(1+ttzhError^2)).
         local vSpeedSigmoid is vSpeedError/sqrt(10+vSpeedError^2).
         print "ttzhError: "+ttzhError at(0, 15).
         print "vSpeedError: "+vSpeedError at(0, 16).
         //print "ttSigmoid: "+ttSigmoid at(0, 17).
         print "vSpeedSigmoid: "+vSpeedSigmoid at(0, 18).
         // Pitch up to maintain descent rate
         lock steering to ship:srfretrograde:forevector*angleAxis(
           max(-vSpeedSigmoid*vang(ship:srfretrograde:forevector, up:forevector), -vang(ship:srfretrograde:forevector, up:forevector)), 
           //max(-vSpeedSigmoid*vang(ship:srfretrograde:forevector, up:forevector), -vang(ship:srfretrograde:forevector, up:forevector)), 
           vcrs(up:forevector, ship:srfretrograde:forevector)
         // This is wrong, vang doesn't give any information about which direction.
         )*angleAxis(choose -vang(vxcl(up:forevector, ship:srfprograde:forevector), vxcl(up:forevector, tgt:position))*2 if alt:radar > 1000 else 0, up:forevector).
         lock throttle to ttImpactSigmoid.
         if abs(alt:radar) < 5 or ship:status = "LANDED" {
            gear on.
            lock throttle to 0.
            return OP_FINISHED.
         } else return OP_CONTINUE.
      }).
//========== End program sequence ===============================
   
}). //End of initializer delegate
