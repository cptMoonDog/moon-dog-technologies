//My attempt at a "perfect" ascent profile.
// New design: The vertical component of Thrust works against g.
// If the Vtwr > 1 apo and etaApo will increase.
// Define ascent profile using Vtwr.  
// If Vtwr < setpoint and apo < target increase throttle, if throttle at max adjust pitch.
// If Vtwr > setpoint increase pitch and if necessary reduce throttle.
   
//James McConnel
//yehoodig@gmail.com

///////////////Script Parameters
set smaTarget to 74000.
set gTurnMag to -3.5.
set gTurnSpeed to 100.
set VtwrSP to 1.1.

//////////////Global Vars
set baseVec to up.
set pitchNS to 0.
set pitchEW to 0.
set r to 0.

list ENGINES IN englist.

set St to 1.

set maxQ to ship:q.
set maxETA to 0.

set t0 to time:seconds. //Time at launch.
set edt to time:seconds.  //Time differential for engine staging trigger.

//Useful Values
lock g to kerbin:mu/((ship:altitude+600000)^2).
lock twr to ship:availablethrust/(ship:mass*g). //eng:thrust/(ship:mass*g).
set OV to Kerbin:radius*sqrt(9.807/(Kerbin:radius+smaTarget)).
lock tto to (OV-ship:velocity:orbit:mag).

/////////////////////Triggers
when time:seconds > edt + 0.5 then{
   if stage:liquidfuel < 0.1 {   //Sequential Staging
      set temp to St.
      set St to 0.
      stage.

      set St to temp.
   }else for eng in englist {    //asp staging
      if eng:ignition and eng:flameout {
         stage.
         list ENGINES in englist.
      }
   }
   set edt to time:seconds.
   if stage:liquidfuel < 0.1 {
      exit.
   } else preserve.
}

////////////////////Functions
function ThrottleSetPoint {
  return max(0.1, (1-ship:altitude/smaTarget)*VtwrSP).
}
function ThrottleProcessVar {
   //Vtwr
   return sin(ship:facing:yaw-up:yaw)*twr.
}

clearscreen.
print "Launch!".

//Ignition
lock throttle to St.
lock pitchEW to 0. 
lock steering to baseVec+R(pitchNS,pitchEW,r).
stage.

until ship:airspeed > gTurnSpeed*twr {
   print "Throttle: " + throttle at(0,0).
   print "Pitch: " + pitchEW at (0,1).
   print " SP: " + ThrottleSetPoint() at (0, 2).
   print "Dynamic Pressure: " + ship:Q at(0, 3).
}
lock pitchEW to gTurnMag.


set r to 0.


//"Gravity Turn" phase
///Throttle PID
lock setPt to ThrottleSetPoint().  
lock pvt to ThrottleProcessVar().

lock Pt to setPt - pvt.
set Pt0 to Pt.
set Stmax to 1.
set Stmin to 0.
set It to 0.
set Dth to 0.

set kPt to 0.03.
set kIt to 0.
set kDt to 0.03.

lock dSt to Pt*kPt + It*kIt + Dth*kDt.


set Vv0 to ship:verticalspeed.

set t0 to time:seconds.

when St < 1 then {
   set kIt to 0.001.
}
until ship:apoapsis > smaTarget*1.1 or ship:obt:eccentricity < 0.001 {
   print "Throttle: " + throttle at(0,0).
   print "Pitch: " + ThrottleProcessVar() at (0,1).
   print "Pitch SP: " + ThrottleSetPoint() at (0, 2).
   print "Dynamic Pressure: " + ship:Q at(0, 3).
   print "MaxQ: " + maxQ at(0,4).
   print "Surface vs orbital yaw: " + (ship:srfprograde:yaw-ship:prograde:yaw) at(0,5).
   print "MaxETA: " + maxETA at(0, 6).
   if ship:q < maxQ*0.01 {
  //    lock baseVec to ship:prograde.
//      lock pitchEW to 0.
      lock baseVec to up.
      lock pitchEW to -90.
      set kIt to 0.
      set kPt to 0.001.
      set kDt to 0.001.
   }
   if ship:altitude > 70000 {
      lock baseVec to up.
      lock pitchEW to -90.
   }
   set dt to time:seconds - t0.
   if dt > 0 {
      set It to It + Pt*dt.
      set Dth to (Pt - Pt0)/dt.
      // If Ki is non-zero, then limit Ki*I to [-1,1]
      if kIt > 0 {
         set It to min(1.0/kIt, max(-1.0/kIt, It)).
      }
      set St to min(Stmax, max(Stmin, St + dSt)).
      set Pt0 to Pt. //Reset previous P value for throttle 
      
      set Vv0 to ship:verticalspeed.
      set t0 to time:seconds.
   }
   wait 0.1.
}

if ship:periapsis < 70000 {
   print "ALERT: FAILED TO ACHIEVE ORBIT. SWITCH TO MANUAL CONTROL.".
}


set St to 0.
set ship:control:pilotmainthrottle to 0.


