@lazyglobal off.
if ship:status = "PRELAUNCH" {
   local landedAltitude is ship:altitude-ship:geoposition:terrainheight.


   local tgt is latlng(10, 0).
   
   lock throttle to 1.
   lock progradePitch to 90-vang(ship:srfprograde:forevector, up:forevector).
   lock tgtHeadingVector to vxcl(up:forevector, tgt:position):normalized.

   lock steering to tgt:position.
   //lock steering to heading(0, 85).
   //lock steering to tgtHeadingVector + R(0, 90, 0).
   stage.
   legs off.
   wait until ship:airspeed > 150.
   lock steering to tgtHeadingVector + R(0, progradePitch, 0).
   wait until ship:orbit:apoapsis > 30000. 
   lock throttle to 0.
   wait until ship:verticalspeed < -5.
   runpath("0:/extra/tiny_boosterlanding.ks", landedAltitude).
}

