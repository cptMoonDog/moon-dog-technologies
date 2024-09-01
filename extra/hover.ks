clearscreen.
if ship:availablethrust <=0 stage.
local maxthrottSetting is 0.
declare function throttleFunction {
   declare parameter targetAltitude.
   declare parameter gLimit is 1.
   
   local currentG is (ship:body:mu/((ship:altitude+ship:body:radius)^2)).
   local twr is ship:availablethrust()/ship:mass.
   local throttMaxGees is twr/currentG.
   local outputMax is choose (1+gLimit)/throttMaxGees if ship:availablethrust() > 0 else 0.
   local outputMin is choose 0.5/throttMaxGees if ship:verticalspeed < 0 else 0.
   local vSpeedError is 0.
   set vSpeedError to (ship:altitude - targetAltitude) + ship:verticalSpeed.
   local vSpeedSigmoid is min(outputMax, max(outputMin, -vSpeedError/sqrt(twr/10+vSpeedError^2))).
   //print "twr: "+twr at(0, 7).
   //print "maxThrott Setting: "+maxThrottSetting at(0, 8).
   //print "outputMax: "+outputMax at(0, 9).
   //print "Sigmoid output: "+vSpeedSigmoid at(0, 10).
   set maxthrottSetting to max(vSpeedSigmoid, maxThrottSetting).
   return vSpeedSigmoid.
}

//local tgtGeoPos is latlng(ship:geoposition:lat, ship:geoposition:lng+0.125).
local tgtGeoPos is latlng(0, ship:geoposition:lng).

declare function translationFunction {
   declare parameter topSpeed is 0.
   declare parameter starSpeed is 0.
   declare maxPitch is 12.5.

   local topSpeedError is topSpeed + ship:velocity:surface*up:topvector.
   local topSpeedSigmoid is topSpeedError/sqrt(1+topSpeedError^2).

   local starSpeedError is starSpeed - ship:velocity:surface*up:starvector.
   local starSpeedSigmoid is starSpeedError/sqrt(1+starSpeedError^2).

   print "top speed Error: "+topSpeedError at(0, 12).
   print "topSigmoid: "+ topSpeedSigmoid at(0, 13).

   print "star speed Error: "+starSpeedError at(0, 15).
   print "starSigmoid: "+starSpeedSigmoid at(0, 16).

   print "tgt distance: "+tgtGeoPos:position:mag at(0, 18).

   //local dir is vecdraw(
   //                  v(0, 0, 0)+up:forevector*2, 
   //                  vxcl(up:forevector, ship:velocity:surface), 
   //                  RGB(1, 1, 0),
   //                  "Traversing",
   //                  1,
   //                  ship:groundspeed > 1,
   //                  0.2,
   //                  true,
   //                  false).

   if abs(topSpeedSigmoid) < 0.1 set topSpeedSigmoid to 0.
   if abs(starSpeedSigmoid) < 0.1 set starSpeedSigmoid to 0.

   return up * R(topSpeedSigmoid*maxPitch, starSpeedSigmoid*maxPitch, 0).
}

lock steering to translationFunction().
local tgtAlt is 80.
lock throttle to throttleFunction(tgtAlt).
wait until ship:altitude >= tgtAlt-1.
lock traverseTop to -min(20, vxcl(up:forevector, tgtGeoPos:position)*up:topVector).
lock traverseStar to min(20, vxcl(up:forevector, tgtGeoPos:position)*up:starVector).

lock steering to translationFunction(traverseTop, traverseStar).
wait 15.
set tgtGeoPos to latlng(0, ship:geoposition:lng+0.03125).
wait until tgtGeoPos:position:mag < 100.
lock steering to translationFunction(0, 0).
wait 10.
set tgtAlt to 65.

wait until ship:status = "LANDED".

