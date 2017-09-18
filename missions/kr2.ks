set countdown to 10.
until countdown < 0 {
   hudtext(countdown+"...", 1, 2, 20, white, true).
   wait 1.
   set countdown to countdown -1.
}
stage.
wait 20.
wait until eta:apoapsis < 10.
stage.
wait until ship:altitude < 10000.
wait until ship:airspeed < 260.
stage.
