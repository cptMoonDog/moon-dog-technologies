// 3 NNs one for each axis of control?

runpath("0:/lib/perceptron.ks").
runpath("0:/extra/hover.ks").

set config:ipu to 2000.
local modelThrott is lexicon().
local modelTop is lexicon().
local modelStar is lexicon().
//local modelName is "3xp".
local modelName is "3xp1h".
if exists("0:/models/"+modelName+"-thrott.json") {
   set modelThrott to perceptron["load model"]("0:/models/"+modelName+"-thrott.json"). 
   set modelTop to perceptron["load model"]("0:/models/"+modelName+"-top.json"). 
   set modelStar to perceptron["load model"]("0:/models/"+modelName+"-star.json"). 
} else {
   modelThrott:add("inputLayer", list(
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
   modelThrott:add("hiddenLayers", list(
      list(
         perceptron["new neuron"](9, 0.001, "relu"),
         perceptron["new neuron"](9, 0.001, "relu"),
         perceptron["new neuron"](9, 0.001, "relu"),
         perceptron["new neuron"](9, 0.001, "relu"),
         perceptron["new neuron"](9, 0.001, "relu"),

         perceptron["new neuron"](9, 0.001, "relu"),
         perceptron["new neuron"](9, 0.001, "relu"),
         perceptron["new neuron"](9, 0.001, "relu"),
         perceptron["new neuron"](9, 0.001, "relu")
      )
   )).
   modelThrott:add("outputLayer", list(
      perceptron["new neuron"](9, 0.001, "sigmoid")
   )).
   modelTop:add("inputLayer", list(
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
   modelTop:add("hiddenLayers", list(
      list(
         perceptron["new neuron"](9, 0.001, "relu"),
         perceptron["new neuron"](9, 0.001, "relu"),
         perceptron["new neuron"](9, 0.001, "relu"),
         perceptron["new neuron"](9, 0.001, "relu"),
         perceptron["new neuron"](9, 0.001, "relu"),

         perceptron["new neuron"](9, 0.001, "relu"),
         perceptron["new neuron"](9, 0.001, "relu"),
         perceptron["new neuron"](9, 0.001, "relu"),
         perceptron["new neuron"](9, 0.001, "relu")
      )
   )).
   modelTop:add("outputLayer", list(
      perceptron["new neuron"](9, 0.001, "sigmoid")
   )).
   modelStar:add("inputLayer", list(
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
   modelStar:add("hiddenLayers", list(
      list(
         perceptron["new neuron"](9, 0.001, "relu"),
         perceptron["new neuron"](9, 0.001, "relu"),
         perceptron["new neuron"](9, 0.001, "relu"),
         perceptron["new neuron"](9, 0.001, "relu"),
         perceptron["new neuron"](9, 0.001, "relu"),

         perceptron["new neuron"](9, 0.001, "relu"),
         perceptron["new neuron"](9, 0.001, "relu"),
         perceptron["new neuron"](9, 0.001, "relu"),
         perceptron["new neuron"](9, 0.001, "relu")
      )
   )).
   modelStar:add("outputLayer", list(
      perceptron["new neuron"](9, 0.001, "sigmoid")
   )).
}


wait 0.

local targetAlt is 30.
local pitchLimit is 30.
local horzSpeedMax is 10.
local horzDistHiRez is 25.
local horzDistLowRez is 1000.
local vertDistMax is 7.5.
local vertSpeedMax is 5.
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
   local topSpeed is vxcl(up:forevector, ship:velocity:surface)*up:topvector.
   local starSpeed is vxcl(up:forevector, ship:velocity:surface)*up:starvector.
   local inputList is list(
        max(-vertSpeedMax, min(vertSpeedMax, ship:verticalspeed))/vertSpeedMax, 
        max(-vertDistMax, min(vertDistMax, targetAlt-alt:radar))/vertDistMax,
        max(-modifiedPitchLimit, min(modifiedPitchLimit, vang(vxcl(up:starvector, ship:facing:forevector), up:forevector)*abs(starDist)/starDist))/modifiedPitchLimit,
        max(-modifiedPitchLimit, min(modifiedPitchLimit, vang(vxcl(up:topvector, ship:facing:forevector), up:forevector)*abs(topDist)/topDist))/modifiedPitchLimit,
        max(0, min(50, maxAccel))/50, // Acceleration m/s
        max(-horzDistHiRez, min(horzDistHiRez, abs(topDist)*topDist))/horzDistHiRez,
        max(-horzDistHiRez, min(horzDistHiRez, abs(starDist)*starDist))/horzDistHiRez,
        max(-horzSpeedMax, min(horzSpeedMax, abs(topSpeed)*topSpeed))/horzSpeedMax,
        max(-horzSpeedMax, min(horzSpeedMax, abs(starSpeed)*starSpeed))/horzSpeedMax
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

local selfTrainthrott is perceptron["evaluate network"](
   normalizedInput(),
   modelThrott["inputLayer"], 
   modelThrott["hiddenLayers"],
   modelThrott["outputLayer"]
).
local selfTrainTop is perceptron["evaluate network"](
   normalizedInput(),
   modelTop["inputLayer"], 
   modelTop["hiddenLayers"],
   modelTop["outputLayer"]
).
local selfTrainStar is perceptron["evaluate network"](
   normalizedInput(),
   modelStar["inputLayer"], 
   modelStar["hiddenLayers"],
   modelStar["outputLayer"]
).
local nOutput is list(
   selfTrainThrott[0],
   selfTrainTop[0],
   selfTrainStar[0]
).
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
           set temp to translationFunction(targetGeoPos, modifiedPitchLimit).
           print "train pitch: "+temp[0]+"            " at(0, 10).
           print "train yaw: "+temp[1]+"            " at(0, 15).
           local pitch is ((temp[0]/modifiedPitchLimit)+1)/2.// if mod(round(time:seconds-startTime), 31) = 0 else 0.5.
           local yaw is ((temp[1]/modifiedPitchLimit)+1)/2.// if mod(round(time:seconds-startTime), 31) = 0 else 0.5.
           set selfTrainThrott to list(max(0, throttleFunction(targetAlt))).
           set selfTrainTop to list(pitch).
           set selfTrainStar to list(yaw).
           if ship:verticalspeed < -vertSpeedMax set selfTrainThrott[0] to 1.
           set nOutput to list(
              perceptron["train network"](
                 normalizedInput(),
                 selfTrainThrott, 
                 modelThrott["inputLayer"], 
                 modelThrott["hiddenLayers"],
                 modelThrott["outputLayer"]
              )[0], 
              perceptron["train network"](
                 normalizedInput(),
                 selfTrainTop, 
                 modelTop["inputLayer"], 
                 modelTop["hiddenLayers"],
                 modelTop["outputLayer"]
              )[0], 
              perceptron["train network"](
                 normalizedInput(),
                 selfTrainStar, 
                 modelStar["inputLayer"], 
                 modelStar["hiddenLayers"],
                 modelStar["outputLayer"]
              )[0] 
           ).
           print "training                   " at(0, 0).
        } else {
           set nOutput to list(
           perceptron["evaluate network"](
              normalizedInput(),
              modelThrott["inputLayer"], 
              modelThrott["hiddenLayers"],
              modelThrott["outputLayer"]
           )[0], 
           perceptron["evaluate network"](
              normalizedInput(),
              modelTop["inputLayer"], 
              modelTop["hiddenLayers"],
              modelTop["outputLayer"]
           )[0], 
           perceptron["evaluate network"](
              normalizedInput(),
              modelStar["inputLayer"], 
              modelStar["hiddenLayers"],
              modelStar["outputLayer"]
           )[0], 
           0, 0).
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
           perceptron["save model"](modelThrott["inputLayer"], modelThrott["hiddenLayers"], modelThrott["outputLayer"], "0:/models/"+modelName+"-thrott.json").
           perceptron["save model"](modelTop["inputLayer"], modelTop["hiddenLayers"], modelTop["outputLayer"], "0:/models/"+modelName+"-top.json").
           perceptron["save model"](modelStar["inputLayer"], modelStar["hiddenLayers"], modelStar["outputLayer"], "0:/models/"+modelName+"-star.json").
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
     set steeringValue to up*R(max(-modifiedPitchLimit, min(modifiedPitchLimit, (nOutput[1]*2-1)*modifiedPitchLimit)), max(-modifiedPitchLimit, min(modifiedPitchLimit, (nOutput[2]*2-1)*modifiedPitchLimit)), 0).
  }
  //set steeringValue to up.

  print "model: "+modelName at(0, 1).
  print "targetAlt: "+targetAlt at(0, 4).
  print "alt:radar: "+alt:radar at(0, 5).
  print "0 (T:N): "+round(selfTrainThrott[0], 3)+":"+round(nOutput[0], 3)+"      " at(0, 6).

  //print "tgtOffsetTop: "+ targetGeoPos:position*up:topvector at(0, 8).
  //print "top (T:N): "+ round(selfTrain[1], 3)+":"+round(nOutput[1], 3) at(0, 9).
  print "nPitch: "+round((nOutput[1]*2-1)*modifiedPitchLimit, 2) at(0, 11).

  //print "tgtOffsetStar: "+ targetGeoPos:position*up:starvector at(0, 13).
  //print "top (T:N): "+ round(selfTrain[2], 3)+":"+round(nOutput[2], 3) at(0, 14).
  print "nYaw: "+round((nOutput[2]*2-1)*modifiedPitchLimit, 2) at(0, 16).
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
