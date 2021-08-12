@lazyglobal off.
if ship:status = "PRELAUNCH" {
   lock throttle to 1.
   lock steering to heading(0, 80).
   stage.
   wait until ship:airspeed > 150.
   lock steering to ship:srfprograde.
   wait until ship:apoapsis > 30000.
   lock throttle to 0.
   runpath("0:/extra/tiny_boosterlanding.ks").
}

