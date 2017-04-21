//Section 0: Declarations and setup.
declare orbitHeight to 75000.
declare pitch to 90.
declare initAngle to 8.
declare function speedLimit {
   if ship:altitude < 5000 {
      return 200.
   } else if ship:altitude < 10000{
      return 200.
   } else if ship:altitude < 20000{
      return 250.
   } else if ship:altitude < 30000{
      return 250.
   } else if ship:altitude < 40000{
      return 300.
   } else if ship:altitude < 50000{
      return 400.
   } else if ship:altitude < 70000{
      return 2500.
   } else {
      return 35000.
   }
}


//Section 1: Liftoff
from {local countdown is 3.} until countdown = 0 step {set countdown to countdown - 1.} do {
//   clearscreen.
   print "T-" + countdown.
   wait 1.   
}
lock steering to heading(90, pitch).
//lock throttle to 1.
lock pitch to 90-90*(ship:altitude/orbitHeight).
//sin(pitch): decrease as trajectory flattens. 
lock throttle to 1 - eta:apoapsis/60.
set sealevel to ship:altitude.
stage.
print "Main engine start...".
when ship:altitude > sealevel + 10 then {
   print "Liftoff...".
}

//////////Trigger functions (When Statements)
if stage:liquidfuel > 0 {
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

//Intra-Atmosphere
until ship:apoapsis > orbitHeight*0.99 {
   //lock pitch to 90-90*((ship:altitude/70000)+(ship:altitude/orbitHeight))/2.
   //min(1, abs(((orbitHeight-ship:altitude)/orbitHeight+(orbitHeight-ship:apoapsis)/orbitHeight + pitch/90)/3)).
}
lock throttle to 0.

//Circularize
lock throttle to cos(pitch) - eta:apoapsis/45.

set p to 90-90*(ship:altitude/orbitHeight).
lock pitch to p.
until ship:periapsis > orbitHeight*0.99 {
   
   if ship:altitude > 70000 and ship:altitude < orbitHeight*1.01 {
      set p to 0.
   } else if ship:altitude > orbitHeight*1.01 {
      set p to 90-90*(ship:altitude/orbitHeight).
   } else {
      set p to 90-90*(ship:altitude/orbitHeight).
   }
}
set ship:control:pilotmainthrottle to 0.
