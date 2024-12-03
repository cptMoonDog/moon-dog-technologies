runpath("0:/lib/perceptron.ks").
runpath("0:/extra/hover.ks").

set config:ipu to 2000.
local model is lexicon().
local nOutput is list().
local latNeuronOutput is 0.
local lngNeuronOutput is 0.
local modelName is "3n9-18x2-3".
if exists("0:/models/"+modelName+".json") {
   set model to perceptron["load model"]("0:/models/"+modelName+".json"). 
} else {
   model:add("inputLayer", list(
      perceptron["new neuron"](1, 0.1, "linear"),  // Inputs: ship:verticalspeed / Max
      perceptron["new neuron"](1, 0.1, "linear"),  // Inputs: targetAlt - alt:radar / Max
      perceptron["new neuron"](1, 0.1, "linear"),  // Inputs: pitch along topvector
      perceptron["new neuron"](1, 0.1, "linear"),  // Inputs: pitch along starvector
      perceptron["new neuron"](1, 0.1, "linear"),  // Inputs: maxAccel
      perceptron["new neuron"](1, 0.1, "linear"),  // Inputs: lat offset
      perceptron["new neuron"](1, 0.1, "linear"),  // Inputs: lng offset
      perceptron["new neuron"](1, 0.1, "linear"),  // Inputs: starvelocity
      perceptron["new neuron"](1, 0.1, "linear")   // Inputs: topvelocity
   )).
   model:add("hiddenLayers", list(
      list(
         perceptron["new neuron"](9, 0.01, "relu"),
         perceptron["new neuron"](9, 0.01, "relu"),
         perceptron["new neuron"](9, 0.01, "relu"),
         perceptron["new neuron"](9, 0.01, "relu"),
         perceptron["new neuron"](9, 0.01, "relu"),

         perceptron["new neuron"](9, 0.01, "relu"),
         perceptron["new neuron"](9, 0.01, "relu"),
         perceptron["new neuron"](9, 0.01, "relu")
      ),
      list(
         perceptron["new neuron"](8, 0.001, "relu"),
         perceptron["new neuron"](8, 0.001, "relu"),
         perceptron["new neuron"](8, 0.001, "relu"),
         perceptron["new neuron"](8, 0.001, "relu"),
         perceptron["new neuron"](8, 0.001, "relu"),

         perceptron["new neuron"](8, 0.001, "relu"),
         perceptron["new neuron"](8, 0.001, "relu"),
         perceptron["new neuron"](8, 0.001, "relu")
      )
   )).
   model:add("outputLayer", list(
      perceptron["new neuron"](8, 0.0001, "sigmoid"),
      perceptron["new neuron"](8, 0.0001, "sigmoid"),
      perceptron["new neuron"](8, 0.0001, "sigmoid")
   )).
}

//local latNeuron is perceptron["new neuron"](1, 0.01, "sigmoid").
//local lngNeuron is perceptron["new neuron"](1, 0.01, "sigmoid").

wait 0.

local targetAlt is 30.
local startGeoPos is ship:geoposition.
local targetGeoPos is startGeoPos.
set targetXCoord to random()/10-0.050.
set targetYCoord to random()/10-0.050.
set targetGeoPos to latlng(startGeoPos:lat+targetXCoord, startGeoPos:lng+targetYCoord).
local maxAccel is ship:availablethrust()/ship:mass - (ship:body:mu/((ship:altitude+ship:body:radius)^2)).
local normalizedInput is list(
     list(ship:verticalspeed), 
     list(targetAlt-alt:radar),
     list(vang(vxcl(up:starvector, ship:facing:forevector), up:forevector)),
     list(vang(vxcl(up:topvector, ship:facing:forevector), up:forevector)),
     list(maxAccel),
     list(max(-100, min(100, targetGeoPos:position*up:topvector))),
     list(max(-100, min(100, targetGeoPos:position*up:starvector))),
     list(max(-20, min(20, vxcl(up:forevector, ship:velocity:surface)*up:topvector))),
     list(max(-20, min(20, vxcl(up:forevector, ship:velocity:surface)*up:starvector)))
).

local selfTrain is perceptron["evaluate network"](
   normalizedInput,
   model["inputLayer"], 
   model["hiddenLayers"],
   model["outputLayer"]
).
local throttValue is 0.
local steeringValue is up.
lock steering to steeringValue.
lock throttle to throttValue.
if ship:availablethrust <= 0 stage.
local startTime is time:seconds.
local flameout is false.
until false {
  
   set maxAccel to ship:availablethrust()/ship:mass - (ship:body:mu/((alt:radar+ship:body:radius)^2)).
   set normalizedInput to list(
     list(ship:verticalspeed), 
     list(targetAlt-alt:radar),
     list(vang(vxcl(up:starvector, ship:facing:forevector), up:forevector)),
     list(vang(vxcl(up:topvector, ship:facing:forevector), up:forevector)),
     list(maxAccel),
     list(max(-100, min(100, targetGeoPos:position*up:topvector))),
     list(max(-100, min(100, targetGeoPos:position*up:starvector))),
     list(max(-20, min(20, vxcl(up:forevector, ship:velocity:surface)*up:topvector))),
     list(max(-20, min(20, vxcl(up:forevector, ship:velocity:surface)*up:starvector)))
   ).
   set nOutput to perceptron["training supervisor"](
     // Output supervisor
     {
        local tgtDist is vxcl(up:forevector, targetGeoPos:position):mag.
        local trainingFreq is 1.
        if tgtDist < 500 set trainingFreq to 3.
        if tgtDist < 100 set trainingFreq to 5.
        if tgtDist < 10 set trainingFreq to 30.
        // Training Frequency
        if mod(round(time:seconds-startTime), trainingFreq) = 0 {
           set temp to translationFunction(targetGeoPos).
           print "train pitch: "+temp[0]+"            " at(0, 17).
           print "train yaw: "+temp[1]+"            " at(0, 20).
           set selfTrain to list(max(0, throttleFunction(targetAlt)), ((temp[0]/45)+1)/2, ((temp[1]/45)+1)/2).
           set nOutput to perceptron["train network"](
              normalizedInput,
              selfTrain, 
              model["inputLayer"], 
              model["hiddenLayers"],
              model["outputLayer"]
           ).
           print "training                   " at(0, 0).
        } else {
           //set latNeuronOutput to latNeuron["evaluate"](list(targetGeoPos:lat-ship:geoposition:lat)).
           //set lngNeuronOutput to lngNeuron["evaluate"](list(targetGeoPos:lng-ship:geoposition:lng)).
           set nOutput to perceptron["evaluate network"](
              normalizedInput,
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
  if alt:radar > targetAlt + 100 {
     set throttValue to nOutput[0].
     //if ship:verticalspeed < -20 set throttValue to nOutput[0].
     //else set throttValue to 0.
     //set throttValue to nOutput[0].
     //set steeringValue to up.
     set steeringValue to up*R(max(-45, min(45, (nOutput[1]*2-1)*45)), max(-45, min(45, (nOutput[2]*2-1)*45)), 0).
  //} else if ship:verticalspeed < -40 or alt:radar < 15 {
   //  set throttValue to 1.
    // set steeringValue to up.
  } else {
     set throttValue to nOutput[0].
     //set steeringValue to up.
     set steeringValue to up*R(max(-45, min(45, (nOutput[1]*2-1)*45)), max(-45, min(45, (nOutput[2]*2-1)*45)), 0).
     //set steeringValue to up*R(max(-45, min(45, (nOutput[1]*2-1)*45)), max(-45, min(45, (nOutput[2]*2-1)*45)), 0).
     //set steeringValue to up*R(max(-45, min(45, nOutput[1])), max(-45, min(45, nOutput[2])), 0).
     //set steeringValue to up*R(max(-45, min(45, (nOutput[1]*2+1)*45)), max(-45, min(45, (nOutput[2]*2+1)*45)), 0).
  }
  print "nPitch: "+(nOutput[1]*2-1)*45+"            " at(0, 18).
  print "nYaw: "+(nOutput[2]*2-1)*45+"            " at(0, 21).

  print "model: "+modelName at(0, 1).
  print "targetAlt: "+targetAlt at(0, 4).
  print "alt:radar: "+alt:radar at(0, 5).
  print "selfTrain: "+selfTrain[0] +"                                 "at(0, 6).
  print "networkOutput0: "+ nOutput[0]+"                    " at(0, 7).

  print "tgtOffsetTop: "+ targetGeoPos:position*up:topvector at(0, 9).
  print "selfTrain: "+selfTrain[1] +"                                 "at(0, 10).
  print "networkOutput1: "+ nOutput[1]+"                    " at(0, 11).

  print "tgtOffsetStar: "+ targetGeoPos:position*up:starvector at(0, 13).
  print "selfTrain: "+selfTrain[2] +"                                 "at(0, 14).
  print "networkOutput2: "+ nOutput[2]+"                    " at(0, 15).
  if time:seconds > startTime + 60 {
    set startTime to time:seconds.
    set targetAlt to random()*100+20.
    set targetXCoord to random()/10-0.050.
    set targetYCoord to random()/10-0.050.
    set targetGeoPos to latlng(startGeoPos:lat+targetXCoord, startGeoPos:lng+targetYCoord).
  }
  print "countdown: "+(startTime+60-time:seconds) at(0, 2).

}
