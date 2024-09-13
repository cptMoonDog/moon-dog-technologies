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
   if not (defined phys_lib) runpath("0:/lib/physics.ks").
   
//======== Parameters used by the program ====
   // Don't forget to update the standalone system, above, if you change the number of parameters here.

//======== Local Variables =====
      local context is lexicon().
      set context["tgt"] to latlng(lat, lng).

      lock tgtHeadingVector to vxcl(up:forevector, context["tgt"]:position).
      lock spHeadingVector to vxcl(up:forevector, ship:srfprograde:forevector).
      lock facingHeadingVector to vxcl(up:forevector, ship:facing:forevector).
      lock steerHeadingDirection to angleaxis(vang(tgtHeadingVector, -spHeadingVector), up:forevector)*tgtHeadingVector:direction.
//      local tgtHeadingArrow is vecdraw(
//                        v(0, 0, 0), 
//                        {return tgtHeadingVector.},
//                        RGB(1, 0, 0),
//                        "Target Heading",
//                        1,
//                        true,
//                        0.2,
//                        true,
//                        true).

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

//      local srfProArrow is vecdraw(
//                        v(0, 0, 0), 
//                        {return spHeadingVector*10.},
//                        RGB(1, 0, 1),
//                        "prograde Heading",
//                        1,
//                        true,
//                        0.2,
//                        true,
//                        true).
//
//      local steerArrow is vecdraw(
//                        v(0, 0, 0), 
//                        {return spHeadingVector*10.},
//                        RGB(1, 1, 1),
//                        "steering",
//                        1,
//                        true,
//                        0.2,
//                        true,
//                        true).

      declare function ttImpactFlat {
         local vertAccel is (ship:body:mu/((ship:altitude+ship:body:radius)^2)).
         local dist is max(0, ship:altitude-context["tgt"]:terrainheight).

         // Kinematics solved for time with quadratic formula
         return (ship:verticalspeed + sqrt(max(0.001, min(0.001, ship:verticalspeed)^2) + 2*(dist)*vertAccel))/vertAccel.
      }

      declare function suicideBurnSigmoid {
         local error is context["suicideBurnLength"] - context["ttImpactFlat"].
         return error/sqrt(1+error^2).
      }
      // will return + (long), - (short)
      declare function longShortSigmoid {
         local error is context["ttImpactFlat"] - context["ttTarget"].
         // Why?
         //if phys_lib["OVatAlt"](ship:body, ship:altitude)*0.90 > ship:velocity:orbit:mag set error to 0.
         return error/sqrt(max(1, context["ttTarget"])+error^2).
      }

      declare function steeringVectorOverflight {
         local sma is ship:altitude+ship:body:radius.
         return up:forevector*angleAxis(
           //Amount of pitch
           vang(up:forevector, ship:srfretrograde:forevector),
           //90-context["twr1Angle"],
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
         // Pitch that will give twr1.  I.e. Maintain rate of descent/null vertical acceleration at maximum throttle setting.
         local steeringError is compassHeadingFromVector(ship:srfprograde:forevector) - compassHeadingFromVector(context["tgt"]:position).
         local pitchAngle is 0. // twr 1 angle relative to retrograde
         
         print "twrAngle: " + context["twr1Angle"] at(0, 3).
         print "retro angle: " + vang(up:forevector, ship:srfretrograde:forevector) at(0, 4).
         local bottom is (vang(up:forevector, ship:srfretrograde:forevector) - context["twr1Angle"]) - 90.
         print "bottom: "+bottom at(0,5).
         local twrRange is abs(90 - context["twr1Angle"] - vang(up:forevector, ship:srfretrograde:forevector)).
         print "range: " + abs(90 - context["twr1Angle"] - vang(up:forevector, ship:srfretrograde:forevector)) at(0, 6).
         //set pitchAngle to vang(up:forevector, ship:srfretrograde:forevector)*context["longShortSigmoid"].
         set pitchAngle to min(90-vang(ship:retrograde:forevector, up:forevector), max(-90, vang(ship:retrograde:forevector, up:forevector)*context["longShortSigmoid"])).
         if alt:radar < 300 and ship:groundspeed > 100 set pitchAngle to -90.
         //if context["longShortSigmoid"] < 0 {// Short
         //   if ship:verticalspeed < 0 set pitchAngle to max(45, vang(up:forevector, ship:srfretrograde:forevector)*context["longShortSigmoid"]).
         //   else set pitchAngle to 0.
         //   print "pitchangle: "+pitchAngle at(0, 7).
         //} else if context["longShortSigmoid"] > 0
         //   set pitchAngle to (90-vang(up:forevector, ship:srfretrograde:forevector)). // Pitch down no more than retrograde

         //if ship:orbit:periapsis > ship:orbit:body:radius/2 set pitchAngle to 0.
         //if alt:radar > 8000 or ship:groundspeed > 300 set pitchAngle to 0.
         return ship:srfretrograde:forevector*angleAxis(
           //Amount of pitch
           pitchAngle,
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
         return abs(max(context["longShortSigmoid"], suicideBurnSigmoid())).
         //if ship:verticalspeed < 0 return max(context["longShortSigmoid"], suicideBurnSigmoid()).
         //else if context["longShortSigmoid"] > 0 return context["longShortSigmoid"].
         //else return 0.
         //if context["longShortSigmoid"] < 0 {
         //   return max(-context["longShortSigmoid"], suicideBurnSigmoid()).
         //} else if context["longShortSigmoid"] > 0 {
         //   return max(context["longShortSigmoid"], suicideBurnSigmoid()).
         //} else return 0.
      }

      declare function throttleFunction {
         declare parameter targetAltitude.
         
         local currentG is (ship:body:mu/((ship:altitude+ship:body:radius)^2)).
         local maxAccel is ship:availablethrust()/ship:mass. // Lose 1 g for hover
         local throttMaxGees is maxAccel/currentG -1.

         local pitchLimit is arccos(currentG/max(currentG, maxAccel)).

         local gLimit is 1.
         local outputMax is choose max(vang(up:forevector, ship:facing:forevector)/pitchLimit, (1+gLimit)/throttMaxGees) if ship:availablethrust() > 0 else 0.
         //local outputMin is choose currentG/maxAccel if ship:verticalspeed < 0 else 0.  // Minimum 0.5 G
         local speedLimit is choose sqrt(abs(alt:radar - targetAltitude)*currentG) if alt:radar < targetAltitude else -sqrt(abs(alt:radar - targetAltitude)*currentG).
         local vSpeedError is 0.
         set vSpeedError to ship:verticalspeed - speedLimit.
         local vSpeedSigmoid is min(outputMax, -vSpeedError/sqrt(currentG+vSpeedError^2)).
         return vSpeedSigmoid.
      }
      declare function throttleFinalApproach {
         local proximity is vxcl(up:forevector, context["tgt"]:position):mag.//, vxcl(north:forevector, context["tgt"]:position):mag).

         if proximity > 500 return throttleFunction(100).
         else if proximity > 100 or ship:velocity:surface:mag > 10 return throttleFunction(20).
         else if proximity > 20 return throttleFunction(20).
         else if proximity > 10 return throttleFunction(20).
         else if proximity > 1 or abs(ship:verticalspeed) > 1 return throttleFunction(5).
         else if proximity <= 1 and abs(ship:verticalspeed) < 1 return throttleFunction(0).
         else return throttleFunction(5).
      }
      declare function axisFunction {
         declare parameter targetSpeed is 0.
         declare parameter currentSpeed is 0.
         declare parameter speedLimit is 0.
         declare parameter pitchLimit is 12.5.

         local error is currentSpeed - min(speedLimit, max(-speedLimit, targetSpeed)).
         if abs(error) < 0.001 set error to 0.
         return (error/sqrt(pitchLimit+error^2))*pitchLimit.
      }

      declare function translationFunction {
         declare parameter tgtGeoPos is latlng(ship:geoposition:lat, ship:geoposition:lng).

         local topDistance is tgtGeoPos:position*up:topVector.
         local starDistance is -tgtGeoPos:position*up:starVector.
         local speedLimit is min(50, sqrt(vxcl(up:forevector, tgtGeoPos:position):mag)/2).

         local topSpeed is (topDistance/vxcl(up:forevector, tgtGeopos:position):mag)*speedLimit.
         local starSpeed is (starDistance/vxcl(up:forevector, tgtGeopos:position):mag)*speedLimit.

         local currentG is (ship:body:mu/((alt:radar+ship:body:radius)^2)).
         local maxAccel is (ship:availablethrust()/ship:mass) - currentG. // Lose 1 g for hover
         local pitchLimit is min(90, arccos(currentG/max(currentG, maxAccel))).

         print "topSpeed: "+topSpeed at(0, 3).
         print "topDistance: "+topDistance at(0, 4).
         print "starSpeed: "+starSpeed at(0, 6).
         print "starDistance: "+starDistance at(0, 7).

         print "pitchLimit: "+pitchLimit at(0, 10).
         print "speedLimit: "+speedLimit at(0, 11).

         print "Target Distance: "+vxcl(up:forevector, tgtGeoPos:position):mag at(0, 13).
         return up * R(
            axisFunction(topSpeed, ship:velocity:surface*up:topvector, speedLimit, pitchLimit), 
            axisFunction(starSpeed, -ship:velocity:surface*up:starvector, speedLimit, pitchLimit), 
            0
         ).
      }
      declare function steeringVectorFinalApproach {
         return translationFunction(context["tgt"]).
      }


      declare function updateContext {
         local test1 is sin(ship:geoposition:lat)*sin(context["tgt"]:lat).
         local test2 is cos(ship:geoposition:lng)*cos(context["tgt"]:lng)*cos(abs(ship:geoposition:lng - context["tgt"]:lng)).
         local velDegrees is ship:groundspeed*(180/(constant:pi*ship:body:radius)).
         local sma is ship:altitude+ship:body:radius.
         set context["twr1Angle"] to arcsin(max(-1, min(1, 1/(ship:body:mu/(sma^2))*(ship:mass/max(0.1, ship:availablethrust))))).
         set context["ttImpactFlat"] to ttImpactFlat().
         set context["ttTarget"] to min(
           vxcl(up:forevector, context["tgt"]:position):mag/ship:groundspeed,
           arccos(min(1, test1 + test2))/velDegrees
         ).
         set context["longShortSigmoid"] to longShortSigmoid().
         set context["suicideBurnLength"] to ship:velocity:surface:mag/(ship:availablethrust/ship:mass). // Refinement: How much mass is lost in burn?
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
         if (context["ttTarget"] < context["ttImpactFlat"] or context["ttTarget"] < context["suicideBurnLength"]) {
            set kernel_ctl["status"] to "Primary Descent".
            set context["throttleFunction"] to throttlePrimaryDescent@.
            set context["steeringFunction"] to steeringVectorPrimaryDescent@.
            return OP_FINISHED.
         } else return OP_CONTINUE.

      }).

      kernel_ctl["MissionPlanAdd"](programName, {
         updateContext().
         debuggingOutput().
         if alt:radar < 100 or ship:groundspeed < 50 {
            set kernel_ctl["status"] to "Final Approach".
            set context["throttleFunction"] to throttleFinalApproach@.
            set context["steeringFunction"] to steeringVectorFinalApproach@.
           return OP_FINISHED.
         } 
         return OP_CONTINUE.
      }).

      kernel_ctl["MissionPlanAdd"](programName, {
        updateContext().
        if alt:radar < 50 gear on.
        if abs(alt:radar) < 1 or ship:status = "LANDED" {
           lock throttle to 0.
           lock steering to up:forevector.
           clearvecdraws().
           return OP_FINISHED.
        } 
        return OP_CONTINUE.
      }).
//========== End program sequence ===============================
   
}). //End of initializer delegate
