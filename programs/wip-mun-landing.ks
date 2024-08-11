@lazyglobal off.
// Program Template

local programName is "wip-mun-landing". //<------- put the name of the script here

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
            +char(10)+"Usage: add wip-mun-landing [LATITUDE] [LONGITUDE]".
         return.
      }
   } else {
      set kernel_ctl["output"] to
         argv+"Attempts to land at the given coordinates"
         +char(10)+"Usage: add wip-mun-landing [LATITUDE] [LONGITUDE]".
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
      local context is lexicon().
      set context["tgt"] to latlng(lat, lng).

      lock tgtHeadingVector to vxcl(up:forevector, context["tgt"]:position).
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
                        {return context["tgt"]:position.},
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

      declare function ttImpactFlat {
         local vertAccel is (ship:body:mu/((ship:altitude+ship:body:radius)^2)).
         local dist is ship:altitude-context["tgt"]:terrainheight.

         // Kinematics solved for time with quadratic formula
         return (ship:verticalspeed + sqrt(ship:verticalspeed^2 + 2*(dist)*vertAccel))/vertAccel.
      }

      // 
      declare function suicideBurnSigmoid {
         local error is context["suicideBurnLength"] - context["ttImpactFlat"].
         return error/sqrt(1+error^2).
      }
      declare function ttImpactTTTargetSigmoid {
         local error is context["ttImpactFlat"] - context["ttTarget"].
         return error/sqrt(1+error^2).
      }
      // will return + (long), - (short)
      declare function longShortSigmoid {
         local error is context["ttImpactFlat"] - context["ttTarget"].
         if abs(error) < 1 or (error < -1 and error > -5) set error to 0.
         return error/sqrt(10+error^2).
      }

      declare function steeringVectorOverflight {
         local sma is ship:altitude+ship:body:radius.
         local twr1Angle is arcsin(max(-1, min(1, 1/(ship:body:mu/(sma^2))*(ship:mass/max(0.1, ship:availablethrust))))).
         return up:forevector*angleAxis(
           //Amount of pitch
           90-twr1Angle,
           //Axis
           vcrs(up:forevector, ship:srfretrograde:forevector)
         ).
      }
      declare function throttleOverFlight {
         //if context["tgt"]:position:mag < ship:body:radius and context["tgt"]:position:mag/context["ttTarget"] < ship:groundspeed return 1.
         //else return 0.
         return 0.
      }

      declare function steeringVectorPrimaryDescent {
         local sma is ship:altitude+ship:body:radius.
         local twr1Angle is arcsin(max(-1, min(1, 1/(ship:body:mu/(sma^2))*(ship:mass/max(0.1, ship:availablethrust))))).
         local steeringError is compassHeadingFromVector(ship:srfprograde:forevector) - compassHeadingFromVector(context["tgt"]:position).
         return ship:srfretrograde:forevector*angleAxis(
           //Amount of pitch
           min(0, context["longShortSigmoid"])*min(90, min(90-twr1Angle, vang(ship:srfretrograde:forevector, up:forevector))),
           //Axis
           vcrs(up:forevector, ship:srfretrograde:forevector)
         )* angleAxis(
            //Amount of steering
            choose (steeringError)*3 if alt:radar > 1000 else 0, 
            //axis
            up:forevector
         ).
      }
      declare function throttlePrimaryDescent {
         if vang(ship:facing:forevector, up:forevector) < 45 // Short, 
            return max(-context["longShortSigmoid"], suicideBurnSigmoid()).
         else
            return max(context["longShortSigmoid"], suicideBurnSigmoid()).
      }

      declare function steeringVectorFinalApproach {
         return ship:srfRetrograde:forevector.
      }

      declare function throttleFinalApproach {
         return max(suicideBurnSigmoid(), (ship:verticalspeed)/(-alt:radar)).
      }

      declare function updateContext {
         local test1 is sin(ship:geoposition:lat)*sin(context["tgt"]:lat).
         local test2 is cos(ship:geoposition:lng)*cos(context["tgt"]:lng)*cos(abs(ship:geoposition:lng - context["tgt"]:lng)).
         local velDegrees is ship:groundspeed*(180/(constant:pi*ship:body:radius)).
         set context["ttImpactFlat"] to ttImpactFlat().
         set context["ttTarget"] to max(
           context["tgt"]:position:mag/ship:groundspeed,
           arccos(min(1, test1 + test2))/velDegrees
         ).
         set context["longShortSigmoid"] to longShortSigmoid().
         set context["ttImpactTTTSigmoid"] to ttImpactTTTargetSigmoid().
         set context["suicideBurnLength"] to ship:velocity:surface:mag/(ship:maxthrust/ship:mass).
         set context["steeringVector"] to context["steeringFunction"]().
         set context["throttleValue"] to context["throttleFunction"]().
      }
      declare function debuggingOutput {
         //Landing point estimate:
         local ttZeroV is -ship:verticalspeed/((ship:maxthrust/ship:mass)*sin(vang(-ship:facing:forevector, vxcl(up:forevector, -ship:facing:forevector)))). 

         clearscreen.
         print "Long or short: "+context["longShortSigmoid"] at(0,9).
         print "ttTarget: "+context["ttTarget"] at(0, 11).
         print "tti: "+context["ttImpactFlat"] at(0, 12).
         print "ssbL: "+context["suicideBurnLength"] at(0, 13).
         print "tgt compass: "+compassHeadingFromVector(context["tgt"]:position) at(0, 19).
         print "prograde compass: "+compassHeadingFromVector(ship:srfprograde:forevector) at(0, 20).
      }

//=============== Begin program sequence Definition ===============================
      // Assumes spacecraft is already on a low over flight trajectory.
      kernel_ctl["MissionPlanAdd"](programName, {
         set kernel_ctl["status"] to "Overflight".
         set context["throttleFunction"] to throttleOverflight@.
         set context["steeringFunction"] to steeringVectorOverflight@.
         updateContext().
         lock throttle to context["throttleValue"].
         lock steering to context["steeringVector"]. 
         return OP_FINISHED.
      }).
      kernel_ctl["MissionPlanAdd"](programName, {
         updateContext().
         // Orient orbit to target
         debuggingOutput().
         if context["ttTarget"] < context["ttImpactFlat"] or context["ttTarget"] < context["suicideBurnLength"] {
            set kernel_ctl["status"] to "Primary Descent".
            set context["throttleFunction"] to throttlePrimaryDescent@.
            set context["steeringFunction"] to steeringVectorPrimaryDescent@.
            return OP_FINISHED.
         } else return OP_CONTINUE.

      }).

      kernel_ctl["MissionPlanAdd"](programName, {
         updateContext().
         debuggingOutput().
         if alt:radar < 1000 {
            set context["throttleFunction"] to throttleFinalApproach@.
            set context["steeringFunction"] to steeringVectorFinalApproach@.
           return OP_FINISHED.
         } 
         return OP_CONTINUE.
      }).

      kernel_ctl["MissionPlanAdd"](programName, {
         updateContext().
        set kernel_ctl["status"] to "Final approach".
        if alt:radar < 50 gear on.
        if abs(alt:radar) < 5 or ship:status = "LANDED" {
           lock throttle to 0.
           lock steering to up:forevector.
           return OP_FINISHED.
        } 
        return OP_CONTINUE.
      }).
//========== End program sequence ===============================
   
}). //End of initializer delegate
