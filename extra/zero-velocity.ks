@lazyglobal off.

set target to vessel("Berton's Wreckage").

lock relVelocity to (ship:velocity:orbit - target:velocity:orbit).
lock steering to -relVelocity.
local thrott is 0.
lock throttle to thrott.

until false {
   print vang(target:position, relVelocity) at(0, 10).
   print "                   " at(0, 11).
   if target:position:mag < 5000 {
     print "Closing on tgt" at(0, 11).
     if vang(target:position, relVelocity) > 88 and vang(target:position , relVelocity) < 92 set thrott to 1.
     else {
        set thrott to 0.
     }
     if relVelocity:mag < 5 {
        set thrott to 0.
        break.
     }
     
   }
}
