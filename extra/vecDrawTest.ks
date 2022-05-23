@lazyglobal off.

clearvecdraws().

//local tgt is latlng(10, -70).
//print tgt:distance.
//local apoHeight is 40000.

//lock tgtHeadingVector to vxcl(up:forevector, tgt:position).
//lock spHeadingVector to vxcl(up:forevector, ship:srfprograde:forevector).
//lock facingHeadingVector to vxcl(up:forevector, ship:facing:forevector).


//lock steeringVector to heading(tgt:heading, 90*(1-ship:apoapsis/30000)).
//lock steeringVector to heading(90, 90*(1-ship:apoapsis/30000)).
//lock steeringVector to (tgtHeadingVector:normalized-spHeadingVector)*(ship:apoapsis/apoHeight)+up:forevector*(1 - ship:apoapsis/apoHeight).
//
//    declare function LANVector {
//       return angleaxis(ship:orbit:lan, ship:body:angularvel:normalized)*solarprimevector. //Taken from KSLib.  Never would have thought of angularVel in a million years.
//    }
//    declare function LANChangeBurnPointVector {
//       return LANVector()*angleAxis(90, vcrs((-ship:body:position):normalized, ship:prograde:forevector:normalized)).  
//    }
//       
//    
    local panels is ship:modulesnamed("ModuleDeployableSolarPanel").
    local panelFacingVector is v(0,0,0).
    local averageAngleOfIncidence is 0.
    for p in panels {
       if p:part:title = "OX-STAT Photovoltaic Panels" or p:part:title = "OX-STAT-XL Photovoltaic Panels" set panelFacingVector to panelFacingVector -p:part:facing:topvector. // 
       else set panelFacingVector to panelFacingVector +p:part:facing:forevector. // Works for the shielded 1x6
    }
    print panels[0]:part:title.
    print panels[0]:allfieldnames.
    local test is vecdraw(
                            v(0,0,0), 
                            //{return -panels[0]:part:facing:topvector.}, // Works for the fixed OX-stat
                            //{return panels[0]:part:facing:forevector.}, 
                            {return panelFacingVector.},
                            RGB(1, 0, 0),
                            "Panel facing Vector",
                            1,
                            true,
                            0.2,
                            true,
                            true).
//    
//    local lanPointer is vecdraw(
//                            //v(0, 0, 0),
//                            {return ship:body:position.}, 
//                            // 
//                            {return angleaxis(ship:orbit:lan, ship:body:angularvel:normalized)*solarprimevector*ship:body:radius*3.}, //Taken from KSLib.  Never would have gotten in a mission years.
//                            //{return solarprimevector*angleaxis(ship:orbit:lan, )*ship:body:radius*2.},
//                            //{return (solarprimevector-ship:body:position)*angleaxis(-ship:orbit:lan, north:forevector-ship:body:position).},
//                            RGB(0, 1, 0),
//                            "LAN",
//                            1,
//                            true,
//                            0.2,
//                            true,
//                            true).
//    
//    local BurnPointVector is vecdraw(
//                            {return ship:body:position.},
//                            {return LANChangeBurnPointVector()*ship:body:radius*3.},
//                            RGB(1, 1, 0),
//                            "burn point",
//                            1,
//                            true,
//                            0.2,
//                            true,
//                            true).
//    
//    local LANShift is vecdraw(
//                            {return ship:body:position.},
//                            {return LANVector()*angleAxis(10, ship:body:angularvel:normalized)*ship:body:radius*3.},
//                            RGB(0.5, 1, 0),
//                            "new LAN",
//                            1,
//                            true,
//                            0.2,
//                            true,
//                            true).
//    
//    local newNormal is vecdraw(
//                            {return ship:body:position.},
//                            {print vang(LANVector(), vcrs(LANChangeBurnPointVector(), LANVector()*angleAxis(10, ship:body:angularvel:normalized))) at(0,5).
//                            return vcrs(LANChangeBurnPointVector(), LANVector()*angleAxis(10, ship:body:angularvel:normalized))*ship:body:radius*3.},
//                            RGB(1, 0, 1),
//                            "new Plane",
//                            1,
//                            true,
//                            0.2,
//                            true,
//                            true).

//local srfProArrow is vecdraw(
//                        v(0, 0, 0), 
//                        {return spHeadingVector*10.},
//                        RGB(1, 0, 1),
//                        "prograde",
//                        1,
//                        true,
//                        0.2,
//                        true,
//                        true).
//
//local steeringArrow is vecdraw(
//                        v(0, 0, 0), 
//                        {return steeringVector*20.},
//                        RGB(0, 0, 1),
//                        "steering",
//                        1,
//                        true,
//                        0.2,
//                        true,
//                        true).


//lock steering to heading(90, 90*(1-ship:apoapsis/apoHeight)).
//lock steering to steeringVector.
//lock throttle to 1.
//until ship:apoapsis > 10000 {
//   print "tgt heading: "+tgt:heading at(0, 5).
//   print "prograde heading: "+vang(spHeadingVector, north:forevector) at(0, 6).
//   print "bearing: "+tgt:bearing at(0, 7).
//}
//lock steering to steeringVector.
////lock steeringVector to heading(tgt:heading, 90*(1-ship:apoapsis/apoHeight)).
//until ship:apoapsis > apoHeight{
//   print "tgt heading: "+tgt:heading at(0, 5).
//   print "prograde heading: "+vang(spHeadingVector, north:forevector) at(0, 6).
//   print "bearing: "+tgt:bearing at(0, 7).
//}
//lock throttle to 0.
//lock steeringVector to (-tgtHeadingVector:normalized-ship:srfprograde:forevector:normalized).
//
//local throttPID is PIDLOOP().
//set throttPID:setpoint to(tgt:distance*sin(vang(up:forevector, tgt:position))). 
//
////lock throttle to (ship:groundspeed)/(tgt:distance*sin(vang(up:forevector, tgt:position))).
//lock throttle to throttPID:update(tgt:distance*sin(vang(up:forevector, tgt:position)), time:seconds).
//until ship:altitude < 100 {
//   set throttPID:setpoint to ship:groundspeed*ship:groundspeed. 
//}
//   
wait until false.