runpath("0:/lib/perceptron.ks").
runpath("0:/extra/hover.ks").

set config:ipu to 2000.
local model is lexicon().
local modelName is "3n10-12x2-3".
if exists("0:/models/"+modelName+".json") {
   set model to perceptron["load model"]("0:/models/"+modelName+".json"). 
} else {
   model:add("inputLayer", list(
      perceptron["new neuron"](1, 0.001, "linear"),  // Inputs: ship:verticalspeed / Max
      perceptron["new neuron"](1, 0.001, "linear"),  // Inputs: targetAlt - alt:radar / Max
      perceptron["new neuron"](1, 0.001, "linear"),  // Inputs: pitch absolute
      perceptron["new neuron"](1, 0.001, "linear"),  // Inputs: pitch along topvector
      perceptron["new neuron"](1, 0.001, "linear"),  // Inputs: pitch along starvector
      perceptron["new neuron"](1, 0.001, "linear"),  // Inputs: maxAccel
      perceptron["new neuron"](1, 0.001, "linear"),  // Inputs: lat offset
      perceptron["new neuron"](1, 0.001, "linear"),  // Inputs: lng offset
      perceptron["new neuron"](1, 0.001, "linear"),  // Inputs: starvelocity
      perceptron["new neuron"](1, 0.001, "linear")   // Inputs: topvelocity
   )).
   model:add("hiddenLayers", list(
      list(
         perceptron["new neuron"](10, 0.001, "relu"),
         perceptron["new neuron"](10, 0.001, "relu"),
         perceptron["new neuron"](10, 0.001, "relu"),
         perceptron["new neuron"](10, 0.001, "relu"),
         perceptron["new neuron"](10, 0.001, "relu"),

         perceptron["new neuron"](10, 0.001, "relu"),
         perceptron["new neuron"](10, 0.001, "relu"),
         perceptron["new neuron"](10, 0.001, "relu"),
         perceptron["new neuron"](10, 0.001, "relu"),
         perceptron["new neuron"](10, 0.001, "relu"),

         perceptron["new neuron"](10, 0.001, "relu"),
         perceptron["new neuron"](10, 0.001, "relu")
      ),
      list(
         perceptron["new neuron"](12, 0.001, "relu"),
         perceptron["new neuron"](12, 0.001, "relu"),
         perceptron["new neuron"](12, 0.001, "relu"),
         perceptron["new neuron"](12, 0.001, "relu"),
         perceptron["new neuron"](12, 0.001, "relu"),

         perceptron["new neuron"](12, 0.001, "relu"),
         perceptron["new neuron"](12, 0.001, "relu"),
         perceptron["new neuron"](12, 0.001, "relu"),
         perceptron["new neuron"](12, 0.001, "relu"),
         perceptron["new neuron"](12, 0.001, "relu"),

         perceptron["new neuron"](12, 0.001, "relu"),
         perceptron["new neuron"](12, 0.001, "relu")
      )
   )).
   model:add("outputLayer", list(
      perceptron["new neuron"](12, 0.0001, "sigmoid"),
      perceptron["new neuron"](12, 0.0001, "sigmoid"),
      perceptron["new neuron"](12, 0.0001, "sigmoid")
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
     list(max(-30, min(30, ship:verticalspeed))/30), 
     list(max(-100, min(100, targetAlt-alt:radar))/100),
     list(max(-45, min(45, vang(vxcl(up:starvector, ship:facing:forevector), up:forevector)))/45),
     list(max(-45, min(45, vang(vxcl(up:topvector, ship:facing:forevector), up:forevector)))/45),
     list(max(-45, min(45, vang(up:forevector, ship:facing:forevector)))/45),
     list(max(0, min(50, maxAccel))/50), // Acceleration m/s
     list(max(-1000, min(1000, targetGeoPos:position*up:topvector))/1000),
     list(max(-1000, min(1000, targetGeoPos:position*up:starvector))/1000),
     list(max(-20, min(20, vxcl(up:forevector, ship:velocity:surface)*up:topvector))/20),
     list(max(-20, min(20, vxcl(up:forevector, ship:velocity:surface)*up:starvector))/20)
).

local selfTrain is perceptron["evaluate network"](
   normalizedInput,
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
  
   set maxAccel to ship:availablethrust()/ship:mass - (ship:body:mu/((alt:radar+ship:body:radius)^2)).
   print "maxAccel: "+maxAccel at(0, 30).
   set normalizedInput to list(
     list(max(-30, min(30, ship:verticalspeed))/30), 
     list(max(-100, min(100, targetAlt-alt:radar))/100),
     list(max(-45, min(45, vang(vxcl(up:starvector, ship:facing:forevector), up:forevector)))/45),
     list(max(-45, min(45, vang(vxcl(up:topvector, ship:facing:forevector), up:forevector)))/45),
     list(max(-45, min(45, vang(up:forevector, ship:facing:forevector)))/45),
     list(max(0, min(50, maxAccel))/50), // Acceleration m/s
     list(max(-1000, min(1000, targetGeoPos:position*up:topvector))/1000),
     list(max(-1000, min(1000, targetGeoPos:position*up:starvector))/1000),
     list(max(-20, min(20, vxcl(up:forevector, ship:velocity:surface)*up:topvector))/20),
     list(max(-20, min(20, vxcl(up:forevector, ship:velocity:surface)*up:starvector))/20)
   ).
   set nOutput to perceptron["training supervisor"](
     // Output supervisor
     {
        local tgtDist is vxcl(up:forevector, targetGeoPos:position):mag.
        local trainingFreq is 3.
        // Training Frequency
        if mod(round(time:seconds-startTime), trainingFreq) = 0 {
           set temp to translationFunction(targetGeoPos).
           print "train pitch: "+temp[0]+"            " at(0, 17).
           print "train yaw: "+temp[1]+"            " at(0, 20).
           local pitch is ((temp[0]/12.5)+1)/2.// if mod(round(time:seconds-startTime), 31) = 0 else 0.5.
           local yaw is ((temp[1]/12.5)+1)/2.// if mod(round(time:seconds-startTime), 31) = 0 else 0.5.
           //if alt:radar < 5 set pitch to 0.5.
           //if alt:radar < 5 set yaw to 0.5.
           //set selfTrain to list(0.5, pitch, yaw).
           set selfTrain to list(max(0, throttleFunction(targetAlt)), pitch, yaw).
           //if mod(round(time:seconds-startTime), trainingFreq*4) = 0 {
           //   set selfTrain[1] to nOutput[1].
           //   set selfTrain[2] to nOutput[2].
           //} else if mod(round(time:seconds-startTime), trainingFreq*3) = 0 {
           //   set selfTrain[0] to nOutput[0].
           //   set selfTrain[2] to nOutput[2].
           //} else if mod(round(time:seconds-startTime), trainingFreq*2) = 0 {
           //   set selfTrain[0] to nOutput[0].
           //   set selfTrain[1] to nOutput[1].
           //}
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
     //set throttValue to 0.
     set throttValue to 1.
     set steeringValue to up*R(max(-12.5, min(12.5, (nOutput[1]*2-1)*12.5)), max(-12.5, min(12.5, (nOutput[2]*2-1)*12.5)), 0).
  } else {
     //set throttValue to 0.
     set throttValue to nOutput[0].
     //set steeringValue to up.
     set steeringValue to up*R(max(-12.5, min(12.5, (nOutput[1]*2-1)*12.5)), max(-12.5, min(12.5, (nOutput[2]*2-1)*12.5)), 0).
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
    set count to count +1.
    set targetAlt to random()*100+20.
    set targetXCoord to random()/10-0.050.
    set targetYCoord to random()/10-0.050.
    set targetGeoPos to latlng(startGeoPos:lat+targetXCoord, startGeoPos:lng+targetYCoord).
  }
  print "countdown: "+(startTime+60-time:seconds) at(0, 2).

}
