@lazyglobal off.
if ship:status = "PRELAUNCH" {
   lock throttle to 1.
   lock steering to up.
   stage.
   wait until ship:apoapsis > 5000.
   lock throttle to 0.
   runpath("0:/extra/tiny_boosterlanding.ks").
}

