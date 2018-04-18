// Note: functions MUST ACCEPT, but NOT REQUIRE a single parameter.  
//       So, git the parameter a sensible default.
global throttle_functions is lexicon().
throttle_functions:add("constantTWR", {
   parameter twr is 1.5.
   // Adapted from:
   //https://pastebin.com/z3i4WbKD
   local r is ship:altitude+ship:body:radius.
   return twr*(ship:body:mu/(r^2))*(ship:mass/max(0.1, ship:availablethrust)).
}).
//Throttle setting is the inverse ratio of the horizontal component of orbital velocity and orbital velocity at the current altitude.
throttle_functions:add("vOV", {
   parameter throwaway is 0.
   return 1-sin(vang(up:forevector, facing:forevector))*(ship:velocity:orbit:mag/phys_lib["OVatAlt"](Kerbin, ship:altitude)).
}).