//My attempt at a "perfect" ascent profile.
//James McConnel
//yehoodig@gmail.com
//1/28/2017

run include_customLib.
declare parameter inclinationTarget is 0.
declare parameter throttleProfile is lexicon().
declare parameter throttleTableType is "value".

lock throttleProcessVar to ship:apoapsis.
set ix2 to throttleProfile:keys:iterator.
ix2:reset().
ix2:next().
if throttleTableType = "function" {
   set throttleProgram to {return functionSequence(throttleProfile, ix2, throttleProcessVar).}.
} else if throttleTableType = "value" {
   set throttleProgram to {return tableLookup(throttleProfile, ix2, throttleProcessVar).}.
}
declare function tableLookup {
   declare parameter table.
   declare parameter i. //Pointer to working iterator.
   declare parameter procVar. //Process variable value

   //Decrement the iterator in case of reversion in procvar.
   if i:atend OR procVar < i:value {
      i:reset().
      i:next.
      until procVar < i:value OR i:atend 
         if NOT i:atend 
            i:next.
   }
   if i:atend return 0.
   else if procVar > i:value {
      i:next.
      if NOT i:atend return table[i:value].
   } else return table[i:value]().
}

declare function functionSequence {
   declare parameter table.
   declare parameter i. //Pointer to working iterator.
   declare parameter procVar. //Process variable value

   //Decrement the iterator in case of reversion in procvar.
   if i:atend OR procVar < i:value {
      i:reset().
      i:next.
      until procVar < i:value OR i:atend i:next.
   }

   if i:atend return 0.
   else if procVar > i:value {
      i:next.
      if NOT i:atend return table[i:value]().
   } else return table[i:value]().
}


///////////////Script Parameters

//////////////Global Vars
   set ispTot to 0.
   set thrustTot to 0.
   set thrustOverIsp to 0.
   set dETAapo to 1.
   set dapo to 1.
   set dt to 1.
//Constants
set g0 to 9.80665.

//Calculations
//set OrbitAltitude to OrbitAltitude*1000. //Adjust parameter to meters.
set OVatSMATarget to sqrt(Kerbin:mu/(Kerbin:radius+OrbitAltitude)).//Kerbin:radius*sqrt(g0/(Kerbin:radius+OrbitAltitude)).
  //Inclination
set Vx to OVatSMATarget*sin(90-inclinationTarget)-174.97. //174.97: Rotational Velocity of Kerbin at Launchsite.
set Vy to OVatSMATarget*cos(90-inclinationTarget).
set launchAzimuth to arctan(Vx/Vy).

//////////Data
//Settings
//set steeringPitch to 0.

//Tracking Variables
lock g to kerbin:mu/((ship:altitude+600000)^2).
lock twr to min(1,throttle)*(ship:availablethrust/(ship:mass*g)).
lock maxTWR to (ship:availablethrust/(ship:mass*g)).
lock vacTWR to (ship:availablethrustat(0)/(ship:mass*g)).
lock facingPitch to 90-vectorangle(up:forevector, facing:forevector). //...Just trust me on this...
lock Vtwr to maxTWR*sin(facingPitch).
lock Htwr to maxTWR*cos(facingPitch).
lock Hvel to ship:velocity:orbit:mag*cos(progradePitch).
lock OV to Kerbin:radius*sqrt(g0/(Kerbin:radius+ship:altitude)).
lock velAtApo to sqrt(Kerbin:mu*(2/(ship:apoapsis+Kerbin:radius) - 1/(ship:orbit:semimajoraxis))).

lock OVatAPO to Kerbin:radius*sqrt(g0/(Kerbin:radius+ship:apoapsis)).
lock dVCircularize to OVatAPO - sqrt(kerbin:mu*(2/(ship:apoapsis+Kerbin:radius) - 1/ship:orbit:semimajoraxis)).
lock dVtoOV to (OV-ship:velocity:orbit:mag).
lock availableAcceleration to ship:availablethrust/ship:mass.
lock currentAcceleration to sqrt((thrott*Htwr*g)^2 + ((thrott*max(0,Vtwr-1))*g)^2).
lock timeToOVatSteeringPitch to (OV-Hvel)/(max(0.0000001, Htwr)*g).
lock timeToOVatPitch0 to (OV-Hvel)/(max(0.0000001, twr)*g).
lock timeToOV to timeToOVatPitch0.
//lock timeToOrbitAltitude to (-ship:verticalspeed+sqrt(ship:verticalspeed^2 + max(-ship:verticalspeed^2+1, 2*(OrbitAltitude-ship:altitude)*(Vtwr-1)*g)))/((Vtwr-1)*g).
lock timeToCircBurn to 0.
//set newCurve to 0.
lock realApo to ship:altitude + ship:verticalspeed*eta:apoapsis + ((Vtwr-1)*g*(eta:apoapsis^2))/2.

list ENGINES IN englist.

/////////////////////Triggers
set thrott to 1.

function display_telemetry {
   parameter mode.

   //clearscreen.
   print "++++++++++++++++++++++++++++++++++++++++++++++++++++++++" at(0,0).
   print "+" at(0,1).
   print "+" at(0,2).
   print "+" at(0,3).
   print "+" at(0,4).
   print "+" at(0,5).
   print "+" at(0,6).
   print "+" at(0,7).
   print "+" at(0,8).
   print "+" at(0,9).
   print "+" at(0,10).
   print "+" at(0,11).
   print "+" at(55,1).
   print "twr: " + twr at(1,2).
   print "Vtwr: " + Vtwr at (1,3).
   print "Htwr: " + Htwr at (1,4).
   if ship:Q > 0 print "Q: " + ship:Q at(1,5).
   print "OV: " + -dVtoOV at(1, 6).
   print "Pitch:" + (facingPitch) at(1,7).
   //print "Time to APO desired: " + ((dVtoOV)/currentAcceleration + (OrbitAltitude-ship:altitude)/ship:verticalspeed) at(1,8).
   //print "Pitch-turnShape: " + (facingPitch - turnShapeVel) at(1,9).
   print "Throttle:" + throttle  at(1,10).
   print "CircBurn:T-" + (timeToCircBurn) at(1,11).
//   print "newCurve: " + newCurve at(1,11).
   print "Time to OV: " + timeToOV at(1,12).
   print "momentum: " + (ship:velocity:surface:mag*ship:mass) at(1,13).
   print "Horizontal Speed: " + max(1, Hvel) at(1,15).
   print "realApo: " + realApo at(1,16).


   print "Launch Azimuth:" + (arctan(Vx/Vy)) at (1, 14).
   if mode="launch" {
      print "Status: Launch!                                  " at(1,1).
   } else if mode="roll" {
      print "Status: Roll Program.                            " at(1,1).
   } else if mode="pitchover" {
      print "Status: Pitchover Manuever                       " at(1,1).
   } else if mode="gturn" {
      print "Status: Gravity Turn                       " at(1,1).
   } else if mode="coasting" {
      print "Coasting to Apogee                               " at(1,1).
   } else if mode="circularize" {
      print "Circularizing                                    " at(1,1).
   }
}.
////Setup complete, begin program.
clearscreen.
display_telemetry("launch").

////////Ignition Sequence Start!
   //Variables
   lock throttle to throttleProgram().
   set steeringPitch to 90.
   set inclinationHeading to 90.
   
   lock steering to heading(inclinationHeading, steeringPitch).
   set a to ship:altitude.

   //Instructions
   stage.
   wait 1.
   if ship:airspeed < 0.1 { //Some crafts (Kerbal X) throttles up before releasing clamps.
      stage.
   }
///////End Ignition Sequence.

///////Staging trigger/////////
//Install this trigger AFTER ignition.
//SSTO designs may have things like parachutes activated otherwise.
set engine_dt to time:seconds.  //Time differential for engine staging trigger.
declare function reCalculateThrustValues {
   list ENGINES in el.
   for en in el {
      if en:ignition and not en:flameout {
         set thrustTot to thrustTot + en:availablethrust.
         set thrustOverIsp to thrustOverIsp + en:availablethrust/en:vacuumisp.
      }
   }
   set ispTot to thrustTot/thrustOverIsp.
   set fuelRate to thrustTot/(ispTot*g0).
}
//FIXME: stage:fuel seems to be reported as zero early in the launch, after ignition causing multiple staging events leading to things like parachutes engaged at launch.
when time:seconds > engine_dt + 0.5 then{
   if stage:liquidfuel < 0.05 and stage:solidfuel < 0.05 and englist:length > 0 and stage:ready {   //Sequential Staging
      for eng in englist {
         if eng:ignition and eng:flameout {
            if stage:liquidfuel < 0.05 print stage:resources[1] at(1,19).
            stage.
            reCalculateThrustValues().
            break.
         }
      }
//      print "LF:" + stage:liquidfuel + " SF:" + stage:solidfuel + " EngCount:" + englist:length at(1,20).
      list ENGINES in englist.
   }else for eng in englist {    //asp staging
      if eng:ignition and eng:flameout {
         stage.
         reCalculateThrustValues().
         list ENGINES in englist.
      }
   }
   set engine_dt to time:seconds.
   //not proper.  drymass reports all resources.  Non-fuel resources could cause complications.
   if ship:mass > ship:drymass and ship:periapsis < 70000 {
      preserve.
   }
}
lock timeToCircBurn to (dVCircularize/max(1,availableAcceleration))/2. //Max function prevents division by zero.
//lock newCurve to timeToOV/max(1, timeToOrbitAltitude).

///////Liftoff.
   //Hold breath until rocket clears the tower.
   until ship:altitude > a + towerHeight {
      display_telemetry("launch").
   }
//////End Liftoff.

//////Begin Roll Program.
   //Variables
   set inclinationHeading to launchAzimuth.
   set steeringPitch to 90.

   //Instructions
   until vang(ship:facing:starvector, heading(launchAzimuth, 90):starvector) < 0.1 {
      display_telemetry("roll").
   }
   //Triggers
   when ship:orbit:inclination >= inclinationTarget then {
      set inclinationHeading to 90-inclinationTarget.
   }
//////End Roll Program.


//////Pitchover Manuever.
   //progradePitch vs Velocity is more the relevant quantity here.
   set tp0 to time:seconds.
   set steeringPitch to 90-pitchOverAngle.
   until progradePitch < 90-pitchOverAngle and ship:velocity:surface:mag > 100 { //AND ship:velocity:surface:mag*ship:mass > 4500
      display_telemetry("pitchover").
   }
/////End Pitchover Manuever.


/////Begin Gravity Turn.
   //Variables
   set lastETAapo to eta:apoapsis.
   set lastApo to ship:apoapsis.

   set lastProgradePitch to progradePitch.
   set dprogradePitch to 0.
   set steeringCorrection to 0.
   //lock steeringPitch to  progradePitch + steeringCorrection.
   set dt to time:seconds.
   lock decWeight to 1-ship:apoapsis/70000.
   lock steeringPitch to progradePitch.

   //Instructions
   until ship:apoapsis > OrbitAltitude and ship:altitude > 70000{
      display_telemetry("gturn").
      if ship:apoapsis >= OrbitAltitude {
         lock throttle to 0.
         set steeringCorrection to 0.
      }else {
         //If prograde Marker is higher than desired and eta:apoapsis is increasing and no steering up is needed, reduce throttle.
         //if twr < initialTWR set thrott to thrott + 0.01. //steeringCorrection > 0 OR timeToOV < timeToOrbitAltitude   //OR (progradePitch < turnShape())
         //else if twr > twrLimit set thrott to thrott - 0.01. //steeringCorrection <= 0 AND timeToOV > timeToOrbitAltitude //(progradePitch > turnShape())
         //If prograde Marker is lower than desired or steering up is needed, increase throttle
         //If Vtwr is low, rocket is approaching horizontal; add Hvel else maintain gTurn.
//         set thrott to max(thrott, 1-Vtwr).
  //       set thrott to restrictRange(1, 0.1, thrott).

         //if ship:Q > 0.35 set thrott to thrott - 0.01.
         lock throttle to throttleProgram().
      }
      if ship:Q < 0.005 AND vang(ship:prograde:forevector, ship:srfprograde:forevector) < 2 {
         lock progradeVector to ship:prograde.
         //lock steeringPitch to turnShape().
      }
      if ship:altitude > 60000 {
         AG1 ON.
      }
      if ship:altitude > 65000 {
         AG2 ON.
      }
      //if timeToOV > timeToOrbitAltitude*2 //OR progradePitch > turnShape() OR (steeringCorrection > 0 AND dProgradePitch > 0)
      //   set steeringCorrection to RestrictRange((90-steeringPitch), 0, steeringCorrection - 0.1).
      //else if throttle > 0.95 AND timeToOV < timeToOrbitAltitude*2  OR dETAapo < 0//(progradePitch < turnShape()) OR
      //   set steeringCorrection to RestrictRange((90-steeringPitch)*(1-2*ship:Q), 0, steeringCorrection + 0.1).
      if time:seconds > dt + 0.01 {
         set dETAapo to eta:apoapsis - lastETAapo.
         set lastETAapo to eta:apoapsis.
         set dapo to ship:apoapsis - lastApo.
         set lastApo to ship:apoapsis.
         set dprogradePitch to progradePitch - lastProgradePitch.
         set lastProgradePitch to progradePitch.
         set dt to time:seconds.
      }
   }
/////End Gravity Turn.

   if eta:apoapsis < eta:periapsis {
/////Coast to Apoapsis.
      display_telemetry("coasting").
      //lock throttle to 0.
      //lock steeringPitch to max(0, 90-vectorangle(up:forevector, ship:prograde:forevector)). //90-vectorangle(up:forevector, ship:prograde:forevector).
/////End Coast.


/////Circularize
declare function timeToburn {
   declare parameter dV to 0.
   declare parameter timeToImpulsePoint to 0.
   if ispTot = 0 reCalculateThrustValues().
   if ispTot =0 print "ackkk!" at(1, 27).
   set m0 to ship:mass.
   set m2 to m0*constant:e^(-(dV/2)/(ispTot*g0)).
   return timeToImpulsePoint - (m0-m2)/fuelRate.
}.
lock timeToCircBurn to timeToBurn(dVCircularize, eta:apoapsis).
      until timeToCircBurn <= 0 display_telemetry("coasting").
      set steeringPitch to 0.
      set minEcc to ship:orbit:eccentricity.
      lock throttle to 1.
      until ship:orbit:eccentricity > minEcc OR ship:orbit:eccentricity < 0.00009 OR (ship:apoapsis-ship:periapsis) < 100 OR (ship:apoapsis > OrbitAltitude and ship:periapsis > OrbitAltitude) {
         display_telemetry("circularize").
         if ship:periapsis > 0.8*OrbitAltitude lock throttle to ship:orbit:eccentricity*100.
         set minEcc to ship:orbit:eccentricity.
      }
   }
   if ship:periapsis < 70000 {
      clearscreen.
      print "ALERT: FAILED TO ACHIEVE ORBIT. SWITCH TO MANUAL CONTROL.".
   }

lock steering to "kill".
unlock throttle.
set throttle to 0.
set ship:control:pilotmainthrottle to 0.
