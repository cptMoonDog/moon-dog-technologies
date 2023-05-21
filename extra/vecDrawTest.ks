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
//    local panels is ship:modulesnamed("ModuleDeployableSolarPanel").
//    local primary is panels[0]. // Ideally, the biggest.
//    local panelFacingVector is v(0,0,0).
//    local panelTopVector isv(0,0,0).
//    // The part:facing:forevector is parallel with the surface the part is attached to.
//    // the topvector is perpendicular to the surface.
//    // The fixed panels face the opposite direction of the topvector, and 
//    // the rotating panels can face any direction parallel with the surface.
//    // Therefore, the vector to point at the sun, is the sum of the negative
//    // topvectors of the fixed panels, and any convenient vector parallel to the surface for rotating panels, like facing:forevector.
//    for p in panels {
//       set panelTopVector to panelTopVector -p:part:facing:topvector.
//       set panelFacingVector to panelFacingVector +p:part:facing:forevector.
//    }
//    // Fixed panel array
//    if primary:part:title = "OX-STAT Photovoltaic Panels" or primary:part:title = "OX-STAT-XL Photovoltaic Panels" { 
//       if panelTopVector:mag = 0 { // Symmetrical, panels facing radially outward
//          set panelFacingVector to -primary:part:facing:topvector.
//       } else { 
//          set panelFacingVector to panelTopVector.
//       } 
//    } else { // Rotating panel array, probably
//       // Symmetrical radial array
//       if panelTopVector:mag = 0 set panelFacingVector to vcrs(-primary:part:facing:topvector, panelFacingVector)).
//       else set panelFacingVector to vcrs(panelFacingVector, panelTopVector).
//    } 
//    
//   
//    lock steering to ship:facing:forevector*angleaxis(vang(ship:facing:forevector, panelFacingVector), vcrs(ship:facing:forevector, panelFacingVector))).
//    print panels[0]:part:title.
//    print panels[0]:allfieldnames.
    local test is vecdraw(
                            v(0,0,0), 
                            {return vxcl(north:forevector*angleaxis(90, up:forevector), ship:velocity:orbit).},
                            RGB(0, 0, 1),
                            "Polar",
                            100,
                            true,
                            0.01,
                            true,
                            true).
    
    local test2 is vecdraw(
                            v(0, 0, 0),
                            {return vxcl(north:forevector, ship:velocity:orbit).},
                            RGB(1, 1, 0),
                            "Equatorial",
                            100,
                            true,
                            0.01,
                            true,
                            true).
    
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