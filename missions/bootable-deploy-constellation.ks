@lazyglobal off.
until eta:apoapsis < 365 and eta:apoapsis > 360 {
   local start is eta:apoapsis.
   if start < 360 set start to start + ship:orbit:period.
   if kuniverse:timewarp:rate < 2 {
      kuniverse:timewarp:warpto(time:seconds+start-365).
   }
}
kuniverse:timewarp:cancelwarp.
wait 5.
local procs is list().
list processors in procs.
if procs:length = 1{ // Deorbit the mothership.
   lock steering to ship:retrograde.
   wait 30.
   lock throttle to 1.
   wait until ship:orbit:periapsis < 45000.
   lock throttle to 0.
   shutdown.
} else {
   lock steering to prograde.
   local stages is procs:length.
   wait 15.
   until procs:length < stages {
      stage.
      wait 1.
      set ship:name to "Comsat Deployment".
      list processors in procs.
   }
   wait 5.
}