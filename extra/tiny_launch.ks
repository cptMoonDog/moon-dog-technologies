@lazyglobal off.
local runmode is lexicon().
local current_mode is "launch".
local orbit_height is 80000.
local pitchover_angle is 10.
local pitchover_V0 is 100.
local pid is PIDLOOP().

function linearTangent {
   return 90-arctan(18*ship:apoapsis/orbit_height).
}

runmode:add("launch", {
   print "launch!" at(0, 6).
   if ship:altitude > 100 {
      lock steering to heading(90,90).
      set current_mode to "roll".
   }
}).

runmode:add("roll", {
   print "roll" at(0, 6).
   if vang(ship:facing:starvector, heading(90,90):starvector) < 0.5 and ship:airspeed > pitchover_V0 {
      set pitchover_V0 to ship:airspeed.
      lock steering to heading(90, linearTangent()).
      set pid:setpoint to (linearTangent()).
      lock throttle to pid:update(time:seconds, (90-vang(ship:prograde:forevector, up:forevector))).
      set current_mode to "pitchover".
   }
}).

runmode:add("pitchover", {
   print "pitchover" at(0, 6).
   print "arctan: "+ (linearTangent()) at(0, 7).
   print "srfprograde: "+(90-vang(ship:srfprograde:forevector, up:forevector)) at(0, 8).
   print "prograde: "+(90-vang(ship:prograde:forevector, up:forevector)) at(0, 9).
   print "facing: "+(90-vang(ship:facing:forevector, up:forevector)) at(0, 10).
   set pid:setpoint to (linearTangent()).
   if vang(ship:srfprograde:forevector, up:forevector) > pitchover_angle and ship:airspeed > 2*pitchover_V0 {
      lock steering to ship:srfprograde.
      set current_mode to "gravity turn".
   }
}).

runmode:add("gravity turn", {
   print "gravity turn" at(0, 6).
   print "arctan: "+ (linearTangent()) at(0, 7).
   print "srfprograde: "+(90-vang(ship:srfprograde:forevector, up:forevector)) at(0, 8).
   print "prograde: "+(90-vang(ship:prograde:forevector, up:forevector)) at(0, 9).
   print "facing: "+(90-vang(ship:facing:forevector, up:forevector)) at(0, 10).
   print "pid:setpoint: "+pid:setpoint at(0, 12).
   print "ref: "+(90-vang(ship:prograde:forevector, up:forevector)) at(0, 13).

   if ship:orbit:apoapsis > orbit_height {
      lock throttle to 0.
   } else if throttle = 0 {
      lock throttle to pid:update(time:seconds, (90-vang(ship:prograde:forevector, up:forevector))).
   }
   if ship:altitude > ship:body:atm:height {
      lock throttle to 0.
      return.
   } else set pid:setpoint to (linearTangent()).
   local engList is list().
   list ENGINES in engList.
   for eng in engList {
      if eng:ignition and eng:flameout {
            stage.
      }
   }
}).

clearscreen.
lock steering to ship:facing.
lock throttle to 1.
stage.

Until ship:orbit:apoapsis >= orbit_height and ship:altitude > ship:body:atm:height runmode[current_mode]().
