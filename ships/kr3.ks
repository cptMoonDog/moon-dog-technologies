set countdown to 10.
until countdown < 0 {
   hudtext(countdown+"...", 1, 2, 20, white, false).
   wait 1.
   set countdown to countdown -1.
}
stage.
wait until stage:solidfuel < 0.01.
stage.
until eta:apoapsis < 20 wait 1.
stage.
until ship:airspeed < 260 wait 1.
stage.