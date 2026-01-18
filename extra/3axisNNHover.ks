// One NN controlling 3 axes?

runpath("0:/lib/perceptron.ks").
runpath("0:/extra/hover.ks").

set config:ipu to 2000.
local model is lexicon().
local modelName is "3nx5-5-3".
if exists("0:/models/"+modelName+".json") {
   set model to perceptron["load model"]("0:/models/"+modelName+".json"). 
} else {
   model:add("inputLayer", list(
      perceptron["new neuron"](9, 0.001, "linear"),  // Inputs: ship:verticalspeed / Max
      perceptron["new neuron"](9, 0.001, "linear"),  // Inputs: targetAlt - alt:radar / Max
      perceptron["new neuron"](9, 0.001, "linear"),  // Inputs: pitch along topvector
      perceptron["new neuron"](9, 0.001, "linear"),  // Inputs: pitch along starvector
      perceptron["new neuron"](9, 0.001, "linear"),  // Inputs: maxAccel
      perceptron["new neuron"](9, 0.001, "linear"),  // Inputs: lat offset
      perceptron["new neuron"](9, 0.001, "linear"),  // Inputs: lng offset
      perceptron["new neuron"](9, 0.001, "linear"),  // Inputs: starvelocity
      perceptron["new neuron"](9, 0.001, "linear")   // Inputs: topvelocity
   )).
   model:add("hiddenLayers", list(
      list(
         perceptron["new neuron"](9, 0.001, "relu"),
         perceptron["new neuron"](9, 0.001, "relu"),
         perceptron["new neuron"](9, 0.001, "relu"),
         perceptron["new neuron"](9, 0.001, "relu"),
         perceptron["new neuron"](9, 0.001, "relu")
      ),
      list(
         perceptron["new neuron"](5, 0.001, "relu"),
         perceptron["new neuron"](5, 0.001, "relu"),
         perceptron["new neuron"](5, 0.001, "relu"),
         perceptron["new neuron"](5, 0.001, "relu"),
         perceptron["new neuron"](5, 0.001, "relu")
      )
   )).
   model:add("outputLayer", list(
      perceptron["new neuron"](5, 0.001, "sigmoid"),
      perceptron["new neuron"](5, 0.001, "sym_sigmoid"),
      perceptron["new neuron"](5, 0.001, "sym_sigmoid")
   )).
}


wait 0.

local targetAlt is 30.
local pitchLimit is 45.
local horzSpeedMax is 20.
local horzDistHiRez is 50.
local horzDistLowRez is 1000.
local vertDistMax is 5.
local vertSpeedMax is 10.
local startGeoPos is ship:geoposition.
local targetGeoPos is startGeoPos.
set targetXCoord to random()/100-0.005.
set targetYCoord to random()/100-0.005.
set targetGeoPos to latlng(startGeoPos:lat+targetXCoord, startGeoPos:lng+targetYCoord).
local vector is vecdraw(
      v(0,0,0), 
      targetGeoPos:position+up:forevector*targetAlt,
      RGB(1, 1, 0),
      targetGeoPos:position:mag,
      1,
      true,
      0.2,
      true,
      false).
set vector:startupdater to {return v(0,0,0).}.
set vector:vecupdater to {return targetGeoPos:position+up:forevector*targetAlt.}.
//set vector:colorupdater to {return RGB().}
local maxAccel is ship:availablethrust()/ship:mass - (ship:body:mu/((ship:altitude+ship:body:radius)^2)).
declare function normalizedInput {
   local modifiedPitchLimit is max(0.001, pitchLimit*min(1, (targetGeoPos:position:mag/horzDistHiRez))).
   local topDist is targetGeoPos:position*up:topvector.
   local starDist is targetGeoPos:position*up:starVector.
   local topSpeed is ship:velocity:surface*up:topvector.
   local starSpeed is ship:velocity:surface*up:starvector.
   local inputList is list(
        perceptron["normalize value"](vertSpeedMax, -vertSpeedMax, 1, -1, ship:verticalspeed),
        perceptron["normalize value"](vertDistMax, -vertDistMax, 1, -1, targetAlt-alt:radar),
        perceptron["normalize value"](modifiedPitchLimit, -modifiedPitchLimit, 1, -1, vang(vxcl(up:starvector, ship:facing:forevector), up:forevector)*abs(topDist)/topDist),
        perceptron["normalize value"](modifiedPitchLimit, -modifiedPitchLimit, 1, -1, vang(vxcl(up:topvector, ship:facing:forevector), up:forevector)*abs(starDist)/starDist),
        perceptron["normalize value"](50, 0, 1, 0, maxAccel),
        perceptron["normalize value"](horzDistHiRez, -horzDistHiRez, 1, -1, abs(topDist)*topDist),
        perceptron["normalize value"](horzDistHiRez, -horzDistHiRez, 1, -1, abs(starDist)*starDist),
        perceptron["normalize value"](horzSpeedMax, -horzSpeedMax, 1, -1, abs(topSpeed)*topSpeed),
        perceptron["normalize value"](horzSpeedMax, -horzSpeedMax, 1, -1, abs(starSpeed)*starSpeed)
   ).
   return list(
      inputList,
      inputList,
      inputList,
      inputList,
      inputList,
      inputList,
      inputList,
      inputList,
      inputList
   ).
}

local coaches is list(
   perceptron["new coach"](1, 0, 1.0, 0.0, 0.7),
   perceptron["new coach"](1, -1, 0.01, 0, 0.01),
   perceptron["new coach"](1, -1, 0.01, 0, 0.01)
).
local selfTrain is perceptron["evaluate network"](
   normalizedInput(),
   model["inputLayer"], 
   model["hiddenLayers"],
   model["outputLayer"]
).
local nOutput is selfTrain.
local throttValue is 0.
local steeringValue is up.
lock steering to steeringValue.
lock throttle to throttValue.
if ship:availablethrust <= 0 stage.
local startTime is time:seconds.
local count is 0.
local flameout is false.
until false {
  
   local modifiedPitchLimit is max(0.001, pitchLimit*min(1, (targetGeoPos:position:mag/horzDistHiRez))).
   set vector:label to targetGeoPos:position:mag:tostring.
   set maxAccel to ship:availablethrust()/ship:mass - (ship:body:mu/((alt:radar+ship:body:radius)^2)).
   print "maxAccel: "+maxAccel at(0, 18).
   set nOutput to perceptron["training supervisor"](
     // Output supervisor
     {
        local tgtDist is vxcl(up:forevector, targetGeoPos:position):mag.
        local trainingFreq is 2.
        // Training Frequency
        if mod(round(time:seconds-startTime), trainingFreq) = 0 {
           //set nOutput to perceptron["evaluate network"](
           //   normalizedInput(),
           //   model["inputLayer"], 
           //   model["hiddenLayers"],
           //   model["outputLayer"]
           //).
           local topSpeed is ship:velocity:surface*up:topvector.
           local starSpeed is ship:velocity:surface*up:starvector.
           local topDistance is targetGeoPos:position*up:topvector.
           local starDistance is targetGeoPos:position*up:starvector.

           set selfTrain[0] to coaches[0]["update"](
              (targetAlt-alt:radar) // 
              //+(choose min(0, ship:verticalspeed) if alt:radar < targetAlt else max(0, ship:verticalspeed))  // If low ignore positive values, if high ignore negative.
           ).
          
           // Pitch
           //set selfTrain[1] to 0.
           set selfTrain[1] to coaches[1]["update"](
              (-topDistance) // 
              //+topSpeed  //
           ).
            
           // Yaw
           //set selfTrain[2] to 0.
           set selfTrain[2] to coaches[2]["update"](
              (starDistance) // 
              //-starSpeed  //
           ).
           set nOutput to perceptron["train network"](
              normalizedInput(),
              selfTrain, 
              model["inputLayer"], 
              model["hiddenLayers"],
              model["outputLayer"]
           ).

           print "training                   " at(0, 0).

        } else {
           set nOutput to perceptron["evaluate network"](
              normalizedInput(),
              model["inputLayer"], 
              model["hiddenLayers"],
              model["outputLayer"]
           ).
           print "NOT training               " at(0, 0).
        }
        wait 0.

        return nOutput.
     }, 
     // Session supervisor
     {
        list Engines in engList.
        for eng in engList if eng:flameout set flameout to true. 
        // Revert
        if engList:length < 3 or 
           count > 10 or
           alt:radar > 1000 or 
           (ship:verticalspeed < -50 and alt:radar < 100) or 
           ship:verticalspeed < -100 or flameout or 
           vang(ship:facing:forevector, up:forevector) > 90 {
           perceptron["save model"](model["inputLayer"], model["hiddenLayers"], model["outputLayer"], "0:/models/"+modelName+".json").
           wait 0.
           //kuniverse:pause().
           kuniverse:reverttolaunch().
        }
     }
   ).
  
  // Training Overlord
  if alt:radar < 5 {
     set throttValue to 1.
     set steeringValue to up.
  } else {
     set throttValue to nOutput[0].
     set steeringValue to up*R(max(-modifiedPitchLimit, min(modifiedPitchLimit, (nOutput[1])*modifiedPitchLimit)), max(-modifiedPitchLimit, min(modifiedPitchLimit, (nOutput[2])*modifiedPitchLimit)), 0).
  }

  print "model: "+modelName at(0, 1).
  print "targetAlt: "+targetAlt at(0, 4).
  print "alt:radar: "+alt:radar at(0, 5).
  print "0 (T:N): "+round(selfTrain[0], 3)+":"+round(nOutput[0], 3)+"      " at(0, 6).

  print "tgtOffsetTop: "+ targetGeoPos:position*up:topvector at(0, 8).
  print "top (T:N): "+ round(selfTrain[1], 3)+":"+round(nOutput[1], 3) at(0, 9).
  print "nPitch: "+round((nOutput[1])*modifiedPitchLimit, 2) at(0, 11).

  print "tgtOffsetStar: "+ targetGeoPos:position*up:starvector at(0, 13).
  print "top (T:N): "+ round(selfTrain[2], 3)+":"+round(nOutput[2], 3) at(0, 14).
  print "nYaw: "+round((nOutput[2])*modifiedPitchLimit, 2) at(0, 16).
  if time:seconds > startTime + 60 {
    set startTime to time:seconds.
    set count to count +1.
    set targetAlt to random()*100+20.
    set targetXCoord to random()/10-0.050.
    set targetYCoord to random()/10-0.050.
    set targetGeoPos to latlng(startGeoPos:lat+targetXCoord, startGeoPos:lng+targetYCoord).
    //log loss to "0:/trainingLog.txt".
  }
  print "countdown: "+(startTime+60-time:seconds) at(0, 2).

}
