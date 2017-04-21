lock steering to heading(270, 0).
wait 10.
lock throttle to 1.
wait until stage:liquidfuel < 0.01 or ship:periapsis <= 34000.
lock throttle to 0.
lock steering to heading(0, 0).
wait 10.
stage.
wait 1.
lock steering to heading(270, 0).
wait 3.
unlock steering.
wait until ship:airspeed < 260.
stage.
set pilotmainthrottle to 0.
