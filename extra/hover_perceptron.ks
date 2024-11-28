runpath("0:/lib/perceptron.ks").

set config:ipu to 2000.
local model is lexicon().
local nOutput is 0.
if exists("0:/models/261.json") {
   set model to perceptron["load model"]("0:/models/261.json"). 
} else {
   model:add("inputLayer", list(
      // This arrangment should automatically scale the inputs eventually.
      perceptron["new neuron"](1, 0.01, "linear"),  // Inputs: ship:verticalspeed / Max
      perceptron["new neuron"](1, 0.01, "linear")  // Inputs: targetAlt - alt:radar / Max
   )).
   model:add("hiddenLayers", list(
      list(
         perceptron["new neuron"](2, 0.01, "relu"),
         perceptron["new neuron"](2, 0.01, "relu"),
         perceptron["new neuron"](2, 0.01, "relu"),
         perceptron["new neuron"](2, 0.01, "relu"),
         perceptron["new neuron"](2, 0.01, "relu"),
         perceptron["new neuron"](2, 0.01, "relu")
      )
   )).
   model:add("outputLayer", list(
      perceptron["new neuron"](6, 0.01, "sigmoid")
   )).
}

wait 0.

local targetAlt is 30.
local maxAccel is ship:availablethrust()/ship:mass - (ship:body:mu/((ship:altitude+ship:body:radius)^2)).
local normalizedInput is list(
     list(ship:verticalspeed), list(targetAlt-alt:radar)
).
//local normalizedInput is list(
//     list(perceptron["normalize value"](10, -10, 10, -10, perceptron["dead zone"]( 1, -1, ship:verticalspeed)),
//     perceptron["normalize value"](30, -30, 10, -10, perceptron["dead zone"]( 1, -1, targetAlt-alt:radar)),
//     perceptron["normalize value"](10, -10, 10, -10, maxAccel)) // acceleration
//).

local selfTrain is perceptron["evaluate network"](
   normalizedInput,
   model["inputLayer"], 
   model["hiddenLayers"],
   model["outputLayer"]
)[0].
local throttValue is 0.
lock steering to up.
lock throttle to throttValue.
if ship:availablethrust <= 0 stage.
local startTime is time:seconds.
local flameout is false.
until false {
  
   set maxAccel to ship:availablethrust()/ship:mass - (ship:body:mu/((alt:radar+ship:body:radius)^2)).
   set normalizedInput to list(
     list(ship:verticalspeed), list(targetAlt-alt:radar)
   ).
//   set normalizedInput to list(
//     list(perceptron["normalize value"](10, -10, 10, -10, perceptron["dead zone"]( 1, -1, ship:verticalspeed)),
//     perceptron["normalize value"](30, -30, 10, -10, perceptron["dead zone"]( 1, -1, targetAlt-alt:radar)),
//     perceptron["normalize value"](10, -10, 10, -10, maxAccel)) // acceleration
//   ).
   set nOutput to perceptron["training supervisor"](
     // Output supervisor
     {
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
        set selfTrain to max(0, throttleFunction(targetAlt)).
        if mod(time:seconds-startTime, 30) = 0 {
           set nOutput to perceptron["train network"](
              normalizedInput,
              list(selfTrain), 
              model["inputLayer"], 
              model["hiddenLayers"],
              model["outputLayer"]
           )[0].
           print "training" at(0, 0).
        } else {
           set nOutput to perceptron["evaluate network"](
              normalizedInput,
              model["inputLayer"], 
              model["hiddenLayers"],
              model["outputLayer"]
           )[0].
           print "NOT training" at(0, 0).
        }
        wait 0.

        if nOutput:typename = "LIST" set nOutput to nOutput[0].
        return nOutput.
     }, 
     // Session supervisor
     {
        list Engines in engList.
        for eng in engList if eng:flameout set flameout to true. 
        // Revert
        if engList:length < 3 or alt:radar > 1000 or (ship:verticalspeed < -40 and alt:radar < 100) or ship:verticalspeed < -100 or flameout or vang(ship:facing:forevector, up:forevector) > 90 {
           perceptron["save model"](model["inputLayer"], model["hiddenLayers"], model["outputLayer"], "0:/models/261.json").
           wait 1.
           //kuniverse:pause().
           kuniverse:reverttolaunch().
        }
     }
   ).
  
  if alt:radar > targetAlt + 20 set throttValue to 0.
  else set throttValue to nOutput.

  print "targetAlt: "+targetAlt at(0, 6).
  print "alt:radar: "+alt:radar at(0, 7).
  print "selfTrain: "+selfTrain+"                      " at(0, 9).
  print "networkOutput: "+ nOutput+"                   " at(0, 10).
  //print "input: "+normalizedInput at(0, 12).
  model["inputLayer"][0]["print weights"](13, "i1").
  model["inputLayer"][1]["print weights"](17, "i2").
  //model["inputLayer"][2]["print weights"](21).
 //model["hiddenLayers"][0][0]["print weights"](15).
  //model["hiddenLayers"][0][1]["print weights"](24).
  //model["hiddenLayers"][0][2]["print weights"](27).
  //model["hiddenLayers"][1][0]["print weights"](30).
  //model["hiddenLayers"][1][1]["print weights"](33).
  //model["hiddenLayers"][1][2]["print weights"](36).
  model["outputLayer"][0]["print weights"](21, "o").
  if time:seconds > startTime + 10 {
    set startTime to time:seconds.
    set targetAlt to random()*100+5.
  }
  print "countdown: "+(startTime+30-time:seconds) at(0, 2).

}
