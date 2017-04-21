//Section 0: Declarations and setup.
declare orbitHeight to 75000.
declare pitch to 90.
declare midTurnThrottlePCT to 0.2.
declare maxThrottleAtDeg to 4.
declare function speedLimit {
   return 3*sqrt(ship:altitude)+100.13.
}


//Section 1: Liftoff
from {local countdown is 3.} until countdown = 0 step {set countdown to countdown - 1.} do {
//   clearscreen.
   print "T-" + countdown.
   wait 1.   
}
lock steering to heading(90, pitch).
lock throttle to 1.
lock pitch to 90-90*(ship:altitude/orbitHeight).

set sealevel to ship:altitude.
stage.
print "Main engine start...".
when ship:altitude > sealevel + 20 then {
   print "Liftoff...".
}

//////////Trigger functions (When Statements)
if stage:liquidfuel > 0 {
   if not ship:partstagged("liquidBooster"):empty {
      when ship:partstagged("liquidBooster")[0]:resources[0]:amount < 0.01 then {
         print ship:partstagged("liquidBooster")[0]:resources[0]:name.
         print ship:partstagged("liquidBooster")[0]:resources[0]:amount.
         
         stage.
      }
   }
   when stage:liquidfuel < 0.1 then {
      stage.
      if ship:altitude < 70000 {
         preserve.
      }
   }
}
if stage:solidfuel > 0 {
   when stage:solidfuel < 0.1 then {
      stage.
  }
}

//when ship:apoapsis > orbitHeight then {
//   lock throttle to 0.
//}
//when pitch < 45 then {
//   lock throttle to speedLimit()/ship:airspeed.
//}
//set etAp to eta:apoapsis. //just a priming read.
//when pitch < maxThrottleAtDeg then {
//   lock throttle to etAp/eta:apoapsis.
//}
set thrott to 1.
lock throttle to thrott.

until ship:apoapsis > orbitHeight {
   if ship:apoapsis/(orbitHeight) > ship:altitude/ship:apoapsis or ship:airspeed > speedLimit() {
      set thrott to max(0, thrott -0.005).
   } else {
      set thrott to min(1, thrott +0.005).
   }
   if abs(pitch) < 10 {
      set thrott to max(0, thrott + 0.008).
   }
   if ship:verticalspeed < 0 {
      unlock pitch.
      set pitch to min(90, pitch + 0.01).
      set thrott to 1.
   } else {
      lock pitch to 90-90*(ship:altitude/orbitHeight).
   } 
}
//circularize
set etAp to eta:apoapsis.
until ship:periapsis > orbitHeight {
   if eta:apoapsis > 180 and eta:periapsis > eta:apoapsis {
      lock throttle to 0.
   } else if eta:apoapsis < etAp*2 {
      lock throttle to etAp/eta:apoapsis.
   } else if eta:periapsis < eta:apoapsis and ship:apoapsis > 35000{
      print "Failed. Revert to manual control.".
      break.
   }
}


set ship:control:pilotmainthrottle to 0.
