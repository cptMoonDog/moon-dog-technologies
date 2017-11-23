set countdown to 10.
until countdown < 0 {
   hudtext(countdown+"...", 1, 2, 20, white, true).
   wait 1.
   set countdown to countdown -1.
}
stage.
wait until eta:apoapsis < 10.
wait 30.
stage.
