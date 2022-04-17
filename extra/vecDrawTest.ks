@lazyglobal off.

clearvecdraws().

local tgt is latlng(10, -70).
print tgt:distance.
local apoHeight is 40000.

lock tgtHeadingVector to vxcl(up:forevector, tgt:position).
lock spHeadingVector to vxcl(up:forevector, ship:srfprograde:forevector).
lock facingHeadingVector to vxcl(up:forevector, ship:facing:forevector).


//lock steeringVector to heading(tgt:heading, 90*(1-ship:apoapsis/30000)).
//lock steeringVector to heading(90, 90*(1-ship:apoapsis/30000)).
lock steeringVector to (tgtHeadingVector:normalized-spHeadingVector)*(ship:apoapsis/apoHeight)+up:forevector*(1 - ship:apoapsis/apoHeight).

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

local steeringArrow is vecdraw(
                        v(0, 0, 0), 
                        {return steeringVector*20.},
                        RGB(0, 0, 1),
                        "steering",
                        1,
                        true,
                        0.2,
                        true,
                        true).


lock steering to heading(90, 90*(1-ship:apoapsis/apoHeight)).
//lock steering to steeringVector.
lock throttle to 1.
until ship:apoapsis > 10000 {
   print "tgt heading: "+tgt:heading at(0, 5).
   print "prograde heading: "+vang(spHeadingVector, north:forevector) at(0, 6).
   print "bearing: "+tgt:bearing at(0, 7).
}
lock steering to steeringVector.
//lock steeringVector to heading(tgt:heading, 90*(1-ship:apoapsis/apoHeight)).
until ship:apoapsis > apoHeight{
   print "tgt heading: "+tgt:heading at(0, 5).
   print "prograde heading: "+vang(spHeadingVector, north:forevector) at(0, 6).
   print "bearing: "+tgt:bearing at(0, 7).
}
lock throttle to 0.
lock steeringVector to (-tgtHeadingVector:normalized-ship:srfprograde:forevector:normalized).

local throttPID is PIDLOOP().
set throttPID:setpoint to(tgt:distance*sin(vang(up:forevector, tgt:position))). 

//lock throttle to (ship:groundspeed)/(tgt:distance*sin(vang(up:forevector, tgt:position))).
lock throttle to throttPID:update(tgt:distance*sin(vang(up:forevector, tgt:position)), time:seconds).
until ship:altitude < 100 {
   set throttPID:setpoint to ship:groundspeed*ship:groundspeed. 
}
   