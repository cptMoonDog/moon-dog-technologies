if ship:periapsis > 10000 {
   warpto(time:seconds+eta:apoapsis).
   lock steering to ship:retrograde.
   wait until eta:apoapsis > eta:periapsis.
   wait 10.
   until ship:periapsis < 7000 lock throttle to 1.
   lock throttle to 0.
}
local pid is pidloop(1,0,1,0,1).
set pid:setpoint to -1.
until alt:radar < 6 {
   if ship:altitude < 8500 {
      local pitchLimit is vang(up:forevector, ship:srfretrograde:forevector).
      local pitchPV is 3*ship:verticalspeed/(alt:radar).
      lock pitchangle to pitchLimit*(-(pitchPV/sqrt(1+pitchPV^2))).
      lock steering to up:forevector*angleaxis(pitchLimit-min(pitchLimit, pitchAngle), ship:srfretrograde:starvector).
      //lock throttle to thrott.
      local minSafeAlt is 8000.
      local throttPV is ship:verticalspeed*ship:velocity:surface:mag/alt:radar.
      //if ship:periapsis > 0 set throttPV to 1-abs(ship:verticalspeed/sqrt(1+ship:verticalspeed^2)).
      lock throttle to -(throttPV/sqrt(1+throttPV^2)).
      print "pitch: "+pitchangle at(0, 1).
   }
   if alt:radar < 25 gear on.
   print "status: "+ship:status at(0, 15).
}
print "status: "+ship:status at(0, 15).
local minSafeAlt is 8000.
declare function thrott {
   local throttSP is 50*alt:radar/1000.
   if ship:verticalspeed > 0 return 1.
   return (1-alt:radar/minSafeAlt)*0.3+min(1, (ship:velocity:surface:mag/10)).
}
declare function pitchangle {
   local vspeedSP is (-1)*(alt:radar/0.5)/(1+ship:groundspeed).
   print "vspeedSP: "+vspeedSP at(0, 2).
   if ship:verticalspeed > 0 return 0.
   return 90*((1-alt:radar/8000)).
}
