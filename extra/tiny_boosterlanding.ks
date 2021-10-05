@lazyglobal off.
parameter landedHeight.
local minThrott is 1.
lock steering to ship:srfretrograde.
local isp is 290.
local thrust is 153.529. // tons*m/s^2
local lock mf to ship:mass*1000/(constant:e^(ship:airspeed/(isp*constant:g0))). // kg
local ff is thrust*1000/(isp*constant:g0). // kg/s
local lock burntime to abs(mf-ship:mass*1000)/ff.
local terminalVelocity is ship:airspeed.
local lock acceleration to (constant:g0 - thrust/ship:mass)-(ship:airspeed/terminalVelocity)*constant:g0.
local lock suicideAlt to ship:airspeed*burntime+acceleration*burntime*burntime/2.// kinematics equation solved for d.
until ship:altitude-ship:geoposition:terrainheight-landedHeight < suicideAlt {
   print "SuicideAlt: "+suicideAlt at(0, 5).
   print "Adjusted alt: "+(ship:altitude-ship:geoposition:terrainheight-landedHeight) at(0, 6).
   set terminalVelocity to ship:airspeed.
}
lock throttle to suicideAlt/(ship:altitude-ship:geoposition:terrainheight-landedHeight). 
legs on.
until ship:status = "LANDED" {
   if ship:altitude-ship:geoposition:terrainheight-landedHeight > 1 {
      set minThrott to min(minThrott, throttle).
      print "Throttle: "+throttle at(0, 9).
      print "Minimum Throttle: "+minThrott at(0, 10).
   }
}
lock throttle to 0.