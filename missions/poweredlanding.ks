@lazyglobal off.
runpath("0:/lib/core/kernel.ks").
mission_plan:add({
   if ship:orbit:periapsis > 45000 and ship:verticalspeed < 0 {
      lock steering to ship:orbit:retrograde.
      wait until vang(ship:facing:forevector, ship:orbit:retrograde) < 0.5.
      lock throttle to 1.
      return OP_CONTINUE.
   } else if ship:orbit:periapsis < 45000 {
      lock throttle to 0.
      return OP_FINISHED.
   }
   return OP_CONTINUE.
}).
mission_plan:add({
local runmode is lexicon().
local current_mode is "coast".
local pid is PIDLOOP().

local isp is 290.
local thrust is 153.529.
lock thrust to ship:availablethrust.
local ff is thrust*1000/(isp*constant:g0).

local dV is 0.
local mf is 0.
local burntime is 0.
local starttime to time:seconds.

local suicideAlt is 0.
local acceleration is 0.

local speedFactor is 0.2.

local engList is 0.
list engines in engList.

lock steering to ship:srfretrograde.
runmode:add("coast", {
   set dV to ship:airspeed.
   set mf to ship:mass*1000/(constant:e^(dV/(isp*constant:g0))).
   print "mf: "+mf at(0, 9).
   set burntime to abs(mf-ship:mass*1000)/ff.
   //set acceleration to constant:g0.
   set acceleration to constant:g0 - thrust/ship:mass. // Thrust is in kN and mass is in tons.  Units cancel.
   //set burntime to burntime+throttleUpTime.

   set suicideAlt to ship:airspeed*burntime+acceleration*burntime*burntime/2.// kinematics equation solved for d.
   print "coast" at(0, 3).
   print "burntime: "+burntime at(0, 7).
   print "m0: "+ship:mass*1000 at(0, 8).
   print "ff: "+ff at(0, 11).
   print "a: "+acceleration at(0, 12).
   print "suicideAlt: "+suicideAlt at(0, 13).
   if ship:altitude-ship:geoposition:terrainheight < suicideAlt { 
      //set pid:setpoint to suicideAlt+10.
      //lock throttle to pid:update(time:seconds, ship:altitude-ship:geoposition:terrainheight).
      //legs on.
      //set current_mode to "controlled".

      lock throttle to 1.
      set starttime to time:seconds.
      legs on.
      set current_mode to "burn".
   }
}).

runmode:add("burn", {
   print "burn" at(0, 3).
   if time:seconds > starttime+burntime {
      set pid:setpoint to -(ship:altitude-ship:geoposition:terrainheight)*speedFactor.
      lock throttle to pid:update(time:seconds, ship:verticalspeed).
      if ship:airspeed < 5 lock steering to up.
      set current_mode to "hover".
   }
}).


runmode:add("hover", {
   print "hover" at(0, 3).
   set pid:setpoint to -(ship:altitude-ship:geoposition:terrainheight)*speedFactor.
   if ship:status = "LANDED" {
      lock throttle to 0.
      set current_mode to "finished".
   }
}).

runmode:add("controlled", {
   set dV to ship:airspeed.
   set mf to ship:mass*1000/(constant:e^(dV/(isp*constant:g0))).
   print "mf: "+mf at(0, 9).
   set burntime to abs(mf-ship:mass*1000)/ff.
   //set acceleration to constant:g0.
   set acceleration to constant:g0 - thrust/ship:mass. // Thrust is in kN and mass is in tons.  Units cancel.
   //set burntime to burntime+throttleUpTime.

   set suicideAlt to ship:airspeed*burntime+acceleration*burntime*burntime/2.// kinematics equation solved for d.
   set pid:setpoint to suicideAlt+10.

   print "coast" at(0, 3).
   print "burntime: "+burntime at(0, 7).
   print "m0: "+ship:mass*1000 at(0, 8).
   print "ff: "+ff at(0, 11).
   print "a: "+acceleration at(0, 12).
   print "suicideAlt: "+suicideAlt at(0, 13).
   if ship:status = "LANDED" {
      lock throttle to 0.
      set current_mode to "finished".
   }
}).
   


clearscreen.

Until current_mode = "finished" runmode[current_mode]().
return OP_FINISHED.
}).
kernel_ctl["start"]().
