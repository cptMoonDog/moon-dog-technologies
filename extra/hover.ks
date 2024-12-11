//clearscreen.
//if ship:availablethrust <=0 stage.

declare function throttleFunction {
   declare parameter targetAltitude.
   
   local currentG is (ship:body:mu/((alt:radar+ship:body:radius)^2)).
   local maxAccel is ship:availablethrust()/ship:mass. // Lose 1 g for hover
   local throttMaxGees is maxAccel/currentG -1.

   local pitchLimit is arccos(currentG/max(currentG, maxAccel)).

   local gLimit is 1.
   local outputMax is choose max(vang(up:forevector, ship:facing:forevector)/pitchLimit, (1+gLimit)/throttMaxGees) if ship:availablethrust() > 0 else 0.
   //local outputMin is choose currentG/maxAccel if ship:verticalspeed < 0 else 0.  // Minimum 0.5 G
   local speedLimit is choose sqrt(abs(alt:radar - targetAltitude)*currentG) if alt:radar < targetAltitude else -sqrt(abs(alt:radar - targetAltitude)*currentG).
   local vSpeedError is 0.
   set vSpeedError to ship:verticalspeed - speedLimit.
   local vSpeedSigmoid is min(outputMax, -vSpeedError/sqrt(currentG+vSpeedError^2)).
   return vSpeedSigmoid.
}


declare function axisFunction {
   declare parameter targetSpeed is 0.
   declare parameter currentSpeed is 0.
   declare parameter speedLimit is 0.
   declare parameter pitchLimit is 65.

   local error is currentSpeed - min(speedLimit, max(-speedLimit, targetSpeed)).
   if abs(error) < 0.1 set error to 0.
   return (error/sqrt(pitchLimit+error^2))*pitchLimit.
}

declare function translationFunction {
   declare parameter tgtGeoPos is latlng(ship:geoposition:lat, ship:geoposition:lng).
   declare parameter pitchLimit is 45.

   local topDistance is tgtGeoPos:position*up:topVector.
   local starDistance is -tgtGeoPos:position*up:starVector.
   local speedLimit is min(50, sqrt(vxcl(up:forevector, tgtGeoPos:position):mag)*2).

   local topSpeed is (topDistance/vxcl(up:forevector, tgtGeopos:position):mag)*speedLimit.
   local starSpeed is (starDistance/vxcl(up:forevector, tgtGeopos:position):mag)*speedLimit.

   local currentG is (ship:body:mu/((alt:radar+ship:body:radius)^2)).
   local maxAccel is (ship:availablethrust()/ship:mass). // Lose 1 g for hover
   local pitchLimit is min(45, arccos(currentG/max(currentG, maxAccel))).

   //print "topSpeed: "+topSpeed at(0, 3).
   //print "topDistance: "+topDistance at(0, 4).
   //print "starSpeed: "+starSpeed at(0, 6).
   //print "starDistance: "+starDistance at(0, 7).

   //print "pitchLimit: "+pitchLimit at(0, 10).
   //print "speedLimit: "+speedLimit at(0, 11).

   //print "Target Distance: "+vxcl(up:forevector, tgtGeoPos:position):mag at(0, 13).
   return list(
      axisFunction(topSpeed, ship:velocity:surface*up:topvector, speedLimit, pitchLimit), 
      axisFunction(starSpeed, -ship:velocity:surface*up:starvector, speedLimit, pitchLimit)
   ).
      
   //return up * R(
   //   axisFunction(topSpeed, ship:velocity:surface*up:topvector, speedLimit, pitchLimit), 
   //   axisFunction(starSpeed, -ship:velocity:surface*up:starvector, speedLimit, pitchLimit), 
   //   0
   //).
}

//local tgtGeoPos is latlng(ship:geoposition:lat+1, ship:geoposition:lng+1).
//local tgtAlt is 50.
//lock throttle to throttleFunction(tgtAlt).
//lock steering to translationFunction(tgtGeoPos).
//
//wait until tgtGeoPos:position:mag < 100.
//set tgtAlt to 0.


//local tgtGeoPos is latlng(0.1, ship:geoposition:lng-0.0108).
//lock steering to translationFunction().
//local tgtAlt is 200.
//lock throttle to throttleFunction(tgtAlt).
//wait until alt:radar >= tgtAlt-1.
//wait 5.
//lock steering to translationFunction(tgtGeoPos).
//wait 5.
//set tgtAlt to 80.
////wait 15.
////set tgtGeoPos to latlng(0, ship:geoposition:lng+0.03125).
//wait until vxcl(up:forevector, tgtGeoPos:position):mag < 10.
//lock steering to translationFunction().
//wait 5.
//set tgtAlt to 64.
//
//wait until ship:status = "LANDED".

