set countdown to 10.
until countdown < 0 {
   hudtext(countdown+"...", 1, 2, 20, white, false).
   wait 1.
   set countdown to countdown -1.
}
set g0 to 9.80665. //m/s^2
set pitchSetting to 90.
lock progradeVector to ship:srfprograde.
when ship:altitude > 35000 then lock progradeVector to ship:prograde.
lock steering to heading(90, pitchSetting).
lock throttle to 1.
stage.
wait 1.
set pitchSetting to 78.
wait until ship:airspeed > 115. //(vang(facing:forevector, ship:srfprograde:forevector) < 5 and ship:airspeed > 100) or stage:solidfuel < 0.02 or ship:airspeed > 300.
lock pitchSetting to max(90-vang(up:forevector, progradeVector:forevector), 0).
wait until stage:solidfuel < 0.02.
stage.
when stage:liquidfuel < 0.02 then stage.
declare function ascentStep {
   parameter throttleSetting.
   parameter nextApo.
   lock throttle to throttleSetting.
   wait until ship:apoapsis > nextApo.
}
ascentStep(1, 75000).

lock throttle to 0.
until ship:altitude > 70000 {
	if ship:apoapsis < 75000 lock throttle to 0.1.
	else lock throttle to 0.
}
lock pitchSetting to 0.
set OVatAPO to Kerbin:radius*sqrt(g0/(Kerbin:radius+ship:apoapsis)).
set velAtApo to sqrt(Kerbin:mu*(2/(ship:apoapsis+Kerbin:radius) - 1/(ship:orbit:semimajoraxis))).
run maneuver(time:seconds+eta:apoapsis, OVatApo - velAtApo, 325, 31.37588).
set ship:control:pilotmainthrottle to 0.

