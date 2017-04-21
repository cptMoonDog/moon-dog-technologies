//KOS seems to calculate "Prograde" as absolute/orbital, not relative to the planet surface.
//In other words, sitting on the launch pad, a rocket has a "Prograde" vector due east at about 174m/s.

///////////////Script Parameters
set smaTarget to 80000.
set apoLead to 60.
set baseVec to up.
set pitchNS to 0.
set pitchEW to 0.
set r to -180.
set eng to ship:partstagged("engine1")[0].
set reactionTime to 0.5.
set gTurnSpeed to 100.
set gTurnMag to -5.

set Pt to 1.
set kpt to 0.05.

//Useful Values
lock g to kerbin:mu/((ship:altitude+600000)^2).
lock twr to eng:thrust/(ship:mass*g).
lock angleOfAscent to 90-(ship:up:yaw - baseVec:yaw).

/////////////////////Triggers
when ship:altitude > smaTarget/2 then {
   set apoLead to apoLead/(ship:availablethrust/(ship:mass*g)).
}

////////////////////Functions
FUNCTION vertTWR {
   parameter a.
   parameter twr.
   
   return sin(a)*twr.
}

FUNCTION relApoLead {
   return (smaTarget/ship:apoapsis)*apoLead/(vertTWR(angleOfAscent, twr)+1).
}


//Ignition
lock throttle to Pt.
lock steering to baseVec+R(pitchNS,pitchEW,r).
stage.

//Pitchover
wait until ship:airspeed > gTurnSpeed.
set pitchEW to gTurnMag.
wait 5.
set pitchEW to 0.
set now to TIME:seconds.
set r to 0.

//"Gravity Turn" phase
until ship:apoapsis > smaTarget-2000 {
   if ship:altitude > smaTarget/2 {
      set baseVec to ship:prograde.
   }else {
      set baseVec to ship:srfprograde.
   }
   print "Relative Lead: " + relApoLead() at(0,0).
   print "TWR vert: " + vertTWR(angleOfAscent, twr) at(0,1).

   if TIME:seconds >= now + reactionTime {   
      //////Decrease Conditions
      if eta:apoapsis > relApoLead() {
         set Pt to max(Pt-(Pt*kpt+0.01), 0).
         set now to TIME:seconds.
      /////Increase Conditions
      }
      if eta:apoapsis < relApoLead() or ship:apoapsis - ship:periapsis < ship:altitude {
         set Pt to min(Pt+(Pt*kpt+0.01), 1).
         set now to TIME:seconds.
      }
      if Pt = 1 and eta:apoapsis < relApoLead()/2 and ship:altitude > smaTarget/2{
         set pitchEW to 30.
         set now to TIME:seconds.
      }else set pitchEW to 0.
   }
   if stage:liquidfuel < 0.1 {
      set Pt to 0.
      wait 1.
      stage.
      wait 1.
      set eng to ship:partstagged("engine2")[0].
      set Pt to 1.
   }
}

print "goto circularize...".
set baseVec to ship:prograde.
set pitchNS to 0.
set pitchEW to 0.
set r to 0.
set apoLead to apoLead/2.
set Pt to 0.
set curApo to ship:apoapsis.
//Circularization.
until (ship:apoapsis - ship:periapsis) < 1000 or ship:apoapsis > curApo+2000 {
   set baseVec to ship:prograde.
   print "Burn at: " + relApoLead() at(0,0).
   if eta:apoapsis <  apoLead {
      set Pt to min(Pt+0.001, 1).
   }else set Pt to max(Pt-0.001, 0).
   if stage:liquidfuel < 0.1 {
      set Pt to 0.
      wait 1.
      stage.
      wait 1.
      set eng to ship:partstagged("engine2")[0].
      set Pt to 1.
   }
}

set Pt to 0.
set pilotmainthrottle to 0.

