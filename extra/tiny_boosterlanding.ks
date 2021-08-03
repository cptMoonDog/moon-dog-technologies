@lazyglobal off.
local runmode is lexicon().
local current_mode is "coast".
local pid is PIDLOOP().

local isp is 290.
local thrust is 153.529.
lock thrust to ship:availablethrust.
local ff is thrust*1000/(isp*constant:g0).
lock ff to thrust*1000/(isp*constant:g0).

local dV is 0.
local mf is 0.
local burntime is 0.
local starttime to time:seconds.

local suicideAlt is 0.

lock steering to ship:srfretrograde.

runmode:add("coast", {
   set dV to ship:airspeed.
   set mf to ship:mass*1000/(constant:e^(dV/(isp*constant:g0))).
   set burntime to abs(mf-ship:mass*1000)/ff.
   set suicideAlt to ship:airspeed*burntime+constant:g0*burntime*burntime/2.// kinematics equation solved for d.
   print "coast" at(0, 3).
   print "burntime: "+burntime at(0, 7).
   print "m0: "+ship:mass*1000 at(0, 8).
   print "mf: "+mf at(0, 9).
   print "ff: "+ff at(0, 10).
   print "suicideAlt: "+suicideAlt at(0, 11).
   if ship:altitude-ship:geoposition:terrainheight < suicideAlt { 
      lock throttle to 1.
      set starttime to time:seconds.
      set current_mode to "burn".
   }
}).

runmode:add("burn", {
   print "burn" at(0, 3).
   if time:seconds > starttime+burntime {
      set pid:setpoint to -(ship:altitude-ship:geoposition:terrainheight)/10.
      lock throttle to pid:update(time:seconds, ship:verticalspeed).
      legs on.
      set current_mode to "hover".
   }
}).

runmode:add("hover", {
   print "hover" at(0, 3).
   set pid:setpoint to -(ship:altitude-ship:geoposition:terrainheight)/10.
   if ship:status = "LANDED" {
      lock throttle to 0.
      set current_mode to "finished".
   }
}).


clearscreen.

Until current_mode = "finished" runmode[current_mode]().
