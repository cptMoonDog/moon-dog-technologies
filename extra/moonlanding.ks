@lazyglobal off.
clearvecdraws().
local tgt is latlng(10, -70).
lock tgtHeadingVector to vxcl(up:forevector, tgt:position).
lock spHeadingVector to vxcl(up:forevector, ship:srfprograde:forevector).
lock facingHeadingVector to vxcl(up:forevector, ship:facing:forevector).
local tgtHeadingArrow is vecdraw(
                        v(0, 0, 0), 
                        {return tgtHeadingVector.},
                        RGB(1, 0, 0),
                        "Target Heading",
                        1,
                        true,
                        0.2,
                        true,
                        true).

local tgtArrow is vecdraw(
                        v(0, 0, 0), 
                        {return tgt:position.},
                        RGB(1, 1, 0),
                        "Target",
                        1,
                        true,
                        0.2,
                        true,
                        true).

local srfProArrow is vecdraw(
                        v(0, 0, 0), 
                        {return spHeadingVector*10.},
                        RGB(1, 0, 1),
                        "prograde",
                        1,
                        true,
                        0.2,
                        true,
                        true).


declare function compassHeadingVector {
   declare parameter tgt.
   local northAngle is vang(vxcl(up:forevector, tgt), north:forevector).
   local eastAngle is vang(vxcl(up:forevector, tgt), north:starvector).
   local tgtheading is 0. //North.
   if northAngle < 90 and eastAngle < 90 { 
      return northAngle. //Northeast
   } else if northAngle < 90 and eastAngle > 90 { 
      return 360-northAngle. //Northwest
   } else if northAngle > 90 and eastAngle < 90 { 
      return northAngle. //Southeast
   } else if northAngle > 90 and eastAngle > 90 { 
      return 360-northAngle. //Southwest
   }
}

declare function compassVectorAdd {
   declare parameter dir.
   declare parameter axis.
   
   local difference is compassHeadingVector(axis) - compassHeadingVector(dir).
   set difference to difference/2.
   if difference < 0 return compassHeadingVector(axis) - difference.
   else return compassHeadingVector(dir) - difference.
} 

declare function compassReflectVectorAbout {
   declare parameter dir.
   declare parameter axis.
   
   local difference is compassHeadingVector(axis) - compassHeadingVector(dir).
   local reflection is compassHeadingVector(axis) + difference.
   if reflection >= 360 return reflection - 360.
   else return reflection.
} 

declare function RetrogradePitchAngle {
   if ship:altitude > 10000 return 90-vang(up:forevector, ship:retrograde:forevector).
   return 90-vang(up:forevector, ship:srfretrograde:forevector).
}

//lock steering to heading(compassVectorAdd(ship:retrograde:forevector, tgt:position), RetrogradePitchAngle()).
// Aim to bring prograde inline with tgt heading.
lock steering to heading(compassVectorAdd(ship:retrograde:forevector, tgt:position), RetrogradePitchAngle()).
local steeringArrow is vecdraw(
                        v(0, 0, 0), 
                        {return heading(compassVectorAdd(ship:retrograde:forevector, tgt:position), RetrogradePitchAngle()):forevector*20.},
                        RGB(0, 0, 1),
                        "steering",
                        1,
                        true,
                        0.2,
                        true,
                        true).
wait 5.
lock throttle to 0.1.
until abs(compassHeadingVector(ship:prograde:forevector) - compassHeadingVector(tgt:position)) < 0.25 {
   print "angle to target: "+abs(ship:geoposition:lng - tgt:lng) at(0, 2).
   print "heading angle: "+abs(compassHeadingVector(ship:srfprograde:forevector) - compassHeadingVector(tgt:position)) at(0, 3).
   print "distance: "+tgt:position:mag at(0, 4).
}
lock throttle to 0.
lock steering to heading(compassVectorAdd(tgt:position, ship:prograde:forevector)+180, RetrogradePitchAngle()).
wait 5.
lock throttle to 0.1.
wait until ship:periapsis < 0.
lock throttle to 0.
local startVel is ship:velocity:surface:mag.
lock ttZeroH to ship:groundspeed/(ship:maxthrust/ship:mass). 
wait 5.
lock vertAccel to -(ship:body:mu/((ship:altitude+ship:body:radius)^2)). //negative is down.
lock ttImpact to (-ship:verticalspeed - sqrt(max(0, ship:verticalspeed^2 - 2*alt:radar*vertAccel)))/(vertAccel).
local adjuster is 1.
lock throttle to adjuster*(ship:velocity:surface:mag - startVel)/startVel.
until ship:altitude < 30000 {
   print "angle to target: "+abs(ship:geoposition:lng - tgt:lng) at(0, 2).
   print "heading angle: "+abs(compassHeadingVector(ship:srfprograde:forevector) - compassHeadingVector(tgt:position)) at(0, 3).
   print "distance: "+tgt:position:mag at(0, 4).
   print "Time to overflight: "+vxcl(up:forevector, tgt:position):mag/ship:velocity:surface:mag at(0, 5).
   print "Time required to stop: "+ ttZeroH+5 at(0, 6).
   if ttImpact > vxcl(up:forevector, tgt:position):mag/ship:groundspeed+ship:altitude/1000 set adjuster to adjuster*1.01.
   else set adjuster to adjuster*0.99.
}
local thrott is 0. 
lock throttle to thrott.
lock steering to ship:srfretrograde:forevector.
until ship:altitude - ship:geoposition:terrainheight < 5 {
   print "angle to target: "+abs(ship:geoposition:lng - tgt:lng) at(0, 2).
   print "heading angle: "+abs(compassHeadingVector(ship:srfprograde:forevector) - compassHeadingVector(tgt:position)) at(0, 3).
   print "distance: "+tgt:position:mag at(0, 4).
   print "Time to overflight: "+vxcl(up:forevector, tgt:position):mag/ship:velocity:surface:mag at(0, 5).
   print "Time required to stop: "+ ttZeroH+5 at(0, 6).
   local ttZeroSrf is ship:velocity:surface:mag/(ship:maxthrust/ship:mass).
   if ship:verticalspeed > -2 set thrott to 0.
   //else set thrott to throttMargin*ttImpact/min(ttZeroSrf-ttImpact, throttMargin*ttImpact).
   else if ttImpact-3 < ttZeroSrf set thrott to min(1, thrott + 0.01).
   else set thrott to max(0, thrott - 0.01).
}
lock steering to up:forevector.
lock throttle to 0.
