clearscreen.
stage.
local maxthrottSetting is 0.
declare function throttleFunction {
   declare parameter targetAltitude.
   declare parameter gLimit is 1.
   
   local currentG is (ship:body:mu/((ship:altitude+ship:body:radius)^2)).
   local twr is ship:availablethrust()/ship:mass.
   local throttMaxGees is twr/currentG.
   local outputMax is (1+gLimit)/throttMaxGees.
   local outputMin is 0.5/throttMaxGees.
   local vSpeedError is 0.
   set vSpeedError to (ship:altitude - targetAltitude) + ship:verticalSpeed.
   local vSpeedSigmoid is min(outputMax, max(outputMin, -vSpeedError/sqrt(twr/10+vSpeedError^2))).
   print "twr: "+twr at(0, 7).
   print "maxThrott Setting: "+maxThrottSetting at(0, 8).
   print "outputMax: "+outputMax at(0, 9).
   print "Sigmoid output: "+vSpeedSigmoid at(0, 10).
   set maxthrottSetting to max(vSpeedSigmoid, maxThrottSetting).
   return vSpeedSigmoid.
}

declare function translationFunction {
   declare parameter topSpeed is 0.
   declare parameter starSpeed is 0.
   declare speedLimit is 5.

   local topSpeedError is ship:srfprograde:forevector*ship:facing:topvector.
   local starSpeedError is ship:srfprograde:forevector*ship:facing:topvector.
   print "top speed: "+topSpeedError at(0, 11).
   print "star speed: "+starSpeedError at(0, 12).
   return up:forevector.
}

lock steering to translationFunction().
local tgtAlt is 100.
lock throttle to throttleFunction(tgtAlt).
wait until ship:altitude >= tgtAlt-1.
wait 10.
set tgtAlt to 80.
wait until ship:altitude <= tgtAlt+1.
wait 10.
set tgtAlt to 73.

wait until ship:status = "LANDED".

