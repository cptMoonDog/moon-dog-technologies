//New way: P, I and D functions for Pitch and Throttle//Section 0: Declarations and setup.
declare orbitHeight to 75000.
declare pitch to 90.
declare midTurnThrottlePCT to 0.2.
declare maxThrottleAtDeg to 4.
declare function speedLimit {
   if ship:altitude < 50000 {
      return 3*sqrt(ship:altitude)+100.13.
   } else {
      return 3000.
   }
}

//Pitch Procedural function.  Theoretically, what the steering curve should be.
declare function pitchP {
   if ship:apoapsis < orbitHeight {
      return 90-90*(ship:altitude/orbitHeight).
   } else if ship:altitude < 50000 {
      return 90-90*(ship:altitude/orbitHeight).
   } else {
      return 0.   
   }
}

//Account for the errors that add up: verticalSpeed.
declare function pitchI {
   if ship:altitude < orbitHeight {
      if ship:mass > 100 {
         wait 1.
      }
      return (1/ship:verticalspeed)*((orbitHeight-ship:altitude)/orbitHeight)*90.
   } else {
      return 0.
   }
}

//Account for fluctuations from set point
declare function pitchD {
   return 0.
}

//Throttle PID Functions:
//Throttle Procedural
set throttP to 1.
set lastRecAirSpeed to 0.
set etaApoapsis to 0.
declare function throttleP {
   if ship:apoapsis < orbitHeight {
      if ship:altitude < 50000 {
         if ship:airspeed < speedLimit() {
            set throttP to min(1, throttP + 0.001).
         } else {
            set throttP to max(0, throttP - 0.001).
         }
      } else {
         set throttP to 1.
      }
      set etaApoapsis to eta:apoapsis.
   } else if ship:periapsis < orbitHeight{
      if ship:altitude < 50000 {
        set throttP to 0.
     } else {
         if pitch > 0 {
            set throttP to 0.
         } else {
            if eta:apoapsis < etaApoapsis {
               set etaApoapsis to eta:apoapsis*0.9991.
               set throttP to min(1, throttP + 0.1).
            } else if eta:periapsis < eta:apoapsis {
               set throttP to 1.
            } else {
               set throttP to max(0, throttP - 0.1).
            }
         }         
      }
   }
   return throttP.
}

set throttI to 0.
declare function throttleI {
   return throttI.
}
declare function throttleD {
   return 0.
}


//Section 1: Liftoff
from {local countdown is 3.} until countdown = 0 step {set countdown to countdown - 1.} do {
//   clearscreen.
   print "T-" + countdown.
   wait 1.   
}
lock steering to heading(90, pitch).
lock throttle to min(1, max(0, throttleP()+throttleI()+throttleD())).
lock pitch to min(90, max(0, pitchP()+pitchI+pitchD())).
if ship:mass > 100 {
   sas on.
   set sasmode to "stabilityassist".
}

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
}
if stage:solidfuel > 0 {
   when stage:solidfuel < 0.1 then {
      stage.
      set thrott to 1.
  }
}

until ship:periapsis > orbitHeight {
   if stage:liquidfuel < 0.1 {
      print "yes".
      stage.
   }
}

set ship:control:pilotmainthrottle to 0.
