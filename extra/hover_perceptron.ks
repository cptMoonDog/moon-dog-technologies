runpath("0:/lib/perceptron.ks").

set config:ipu to 2000.
local model is lexicon().
local nOutput is 0.
if exists("0:/models/hoverflow6731r.json") {
   set model to perceptron["load model"]("0:/models/hoverflow6731r.json"). 
} else {
   model:add("inputLayer", list(
      // This arrangment should automatically scale the inputs eventually.
      perceptron["new neuron"](1, 0.00001, "relu"),  // Inputs: ship:verticalspeed / Positive
      perceptron["new neuron"](1, 0.00001, "relu"),  // Inputs: ship:verticalspeed / Inverse (negative=positive)
      //perceptron["new neuron"](1, 0.00001, "relu"),  // Inputs: ship:verticalspeed / Maximum (Inverse with offset)
      //perceptron["new neuron"](1, 0.00001, "relu"),  // Inputs: ship:verticalspeed / Minimum (Positive with offset)
      perceptron["new neuron"](1, 0.00001, "relu"),  // Inputs: targetAlt - alt:radar / Positive
      perceptron["new neuron"](1, 0.00001, "relu"),  // Inputs: targetAlt - alt:radar / Negative
      //perceptron["new neuron"](1, 0.00001, "relu"),  // Inputs: targetAlt - alt:radar / Maximum
      //perceptron["new neuron"](1, 0.00001, "relu"),  // Inputs: targetAlt - alt:radar / Minimum
      perceptron["new neuron"](1, 0.00001, "relu"),  // Maximum acceleration / Positive
      perceptron["new neuron"](1, 0.00001, "relu")   // Maximum acceleration / Maximum
   )).
   model:add("hiddenLayers", list(
      list(
        perceptron["new neuron"](6, 0.00001, "relu"),
        perceptron["new neuron"](6, 0.00001, "relu"),
        perceptron["new neuron"](6, 0.00001, "relu"),
        perceptron["new neuron"](6, 0.00001, "relu"),
        perceptron["new neuron"](6, 0.00001, "relu"),
        perceptron["new neuron"](6, 0.00001, "relu"),
        perceptron["new neuron"](6, 0.00001, "relu")
      ),
      list(
        perceptron["new neuron"](7, 0.00001, "relu"),
        perceptron["new neuron"](7, 0.00001, "relu"),
        perceptron["new neuron"](7, 0.00001, "relu")
      )
   )).
   model:add("outputLayer", list(
      perceptron["new neuron"](3, 0.00001, "sigmoid")
   )).
}

wait 0.

local targetAlt is 30.
local maxAccel is ship:availablethrust()/ship:mass - (ship:body:mu/((ship:altitude+ship:body:radius)^2)).
local normalizedInput is list(
     list(ship:verticalspeed),
     list(ship:verticalspeed),
     list(ship:verticalspeed),
     list(ship:verticalspeed),
     list(targetAlt-alt:radar),
     list(targetAlt-alt:radar),
     list(targetAlt-alt:radar),
     list(targetAlt-alt:radar),
     list(maxAccel), // acceleration
     list(maxAccel) // acceleration
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
  print "training" at(0, 0).
  
   set maxAccel to ship:availablethrust()/ship:mass - (ship:body:mu/((alt:radar+ship:body:radius)^2)).
   set normalizedInput to list(
      list(ship:verticalspeed),
      list(ship:verticalspeed),
      list(ship:verticalspeed),
      list(ship:verticalspeed),
      list(targetAlt-alt:radar),
      list(targetAlt-alt:radar),
      list(targetAlt-alt:radar),
      list(targetAlt-alt:radar),
      list(maxAccel), // acceleration
      list(maxAccel) // acceleration
   ).
//   set normalizedInput to list(
//     list(perceptron["normalize value"](10, -10, 10, -10, perceptron["dead zone"]( 1, -1, ship:verticalspeed)),
//     perceptron["normalize value"](30, -30, 10, -10, perceptron["dead zone"]( 1, -1, targetAlt-alt:radar)),
//     perceptron["normalize value"](10, -10, 10, -10, maxAccel)) // acceleration
//   ).
   set nOutput to perceptron["training supervisor"](
     // Output supervisor
     {
        if targetAlt - alt:radar > 0 {
           // Below target
           //set selfTrain to 1-ship:verticalspeed/10.
           if ship:verticalspeed > 10 set selfTrain to min(selfTrain - 0.01, nOutput).
           else if ship:verticalspeed < 1 set selfTrain to max(selfTrain + 0.01, nOutput).
        } else if targetAlt - alt:radar < -1 {
           // Above target
           if ship:verticalspeed > -1 set selfTrain to min(nOutput/2, selfTrain - 0.001).
           else if ship:verticalspeed < -10 set selfTrain to 1.
           else if ship:verticalspeed < -5  set selfTrain to min(nOutput*2, min(0.5, selfTrain + 0.001)).
        }
        if abs(targetAlt - alt:radar) < 1 and abs(ship:verticalspeed) < 1 set selfTrain to nOutput.
        set selfTrain to min(1, max(0, selfTrain)).
        set nOutput to perceptron["train network"](
           normalizedInput,
           list(nOutput+selfTrain), 
           model["inputLayer"], 
           model["hiddenLayers"],
           model["outputLayer"]
        )[0].

        return nOutput.
     }, 
     // Session supervisor
     {
        list Engines in engList.
        for eng in engList if eng:flameout set flameout to true. 
        // Revert
        if alt:radar > 500 or (ship:verticalspeed < -40 and alt:radar < 100) or flameout or vang(ship:facing:forevector, up:forevector) > 90 or missiontime > 15*60 {
           perceptron["save model"](model["inputLayer"], model["hiddenLayers"], model["outputLayer"], "0:/models/hoverflow6731r.json").
           wait 1.
           //kuniverse:pause().
           kuniverse:reverttolaunch().
        }
     }
   ).
  
  set throttValue to nOutput.

  print "targetAlt: "+targetAlt at(0, 6).
  print "alt:radar: "+alt:radar at(0, 7).
  print "selfTrain: "+selfTrain+"                      " at(0, 9).
  print "networkOutput: "+ nOutput+"                   " at(0, 10).
  //print "input: "+normalizedInput at(0, 12).
  //model["inputLayer"][0]["print weights"](15).
  //model["inputLayer"][1]["print weights"](13).
  //model["inputLayer"][2]["print weights"](21).
 //model["hiddenLayers"][0][0]["print weights"](15).
  //model["hiddenLayers"][0][1]["print weights"](24).
  //model["hiddenLayers"][0][2]["print weights"](27).
  //model["hiddenLayers"][1][0]["print weights"](30).
  //model["hiddenLayers"][1][1]["print weights"](33).
  //model["hiddenLayers"][1][2]["print weights"](36).
  //model["outputLayer"][0]["print weights"](18).
  if time:seconds > startTime + 30 {
    set startTime to time:seconds.
    set targetAlt to random()*100+5.
  }
  print "countdown: "+(startTime+30-time:seconds) at(0, 2).

}
