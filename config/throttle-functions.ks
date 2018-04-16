//Throttle setting is the inverse ratio of the horizontal component of orbital velocity and orbital velocity at the current altitude.
throttle_functions:add("vOV", {
   return 1-sin(vang(up:forevector, facing:forevector))*(ship:velocity:orbit:mag/phys_lib["OVatAlt"](Kerbin, ship:altitude)).
}).