@lazyglobal off.
if ship:status = "PRELAUNCH" {
   local landedAltitude is ship:altitude-ship:geoposition:terrainheight.
   lock throttle to 1.
   lock steering to heading(0, 80).
   stage.
   legs off.
   wait until ship:airspeed > 150.
   lock steering to ship:srfprograde.
   wait until ship:apoapsis > 30000.
   lock throttle to 0.
   wait until ship:verticalspeed < -5.
   //runpath("0:/extra/tiny_boosterlanding.ks", landedAltitude).
   runpath("0:/extra/pidlanding.ks", landedAltitude).
}

