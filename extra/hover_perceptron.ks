runpath("0:/lib/perceptron.ks").

set config:ipu to 2000.
local model is lexicon().
local nOutput is 0.
if exists("0:/models/hoverflow.json") {
   set model to perceptron["load model"]("0:/models/hoverflow.json"). 
} else {
   model:add("inputLayer", list(
      perceptron["new neuron"](1, 0.01, "relu"),  // Inputs: ship:verticalspeed
      perceptron["new neuron"](1, 0.01, "relu"),  // Inputs: targetAlt - alt:radar
      perceptron["new neuron"](1, 0.01, "relu")   // Maximum acceleration
   )).
   model:add("hiddenLayers", list(
      list(
         perceptron["new neuron"](3, 0.01, "relu"),
         perceptron["new neuron"](3, 0.01, "relu"),
         perceptron["new neuron"](3, 0.01, "relu"),
         perceptron["new neuron"](3, 0.01, "relu"),
         perceptron["new neuron"](3, 0.01, "relu")
      ),
      list(
         perceptron["new neuron"](5, 0.01, "relu"),
         perceptron["new neuron"](5, 0.01, "relu"),
         perceptron["new neuron"](5, 0.01, "relu")
      )
      //list(
      //   perceptron["new neuron"](3, 0.001, "relu"),
      //   perceptron["new neuron"](3, 0.001, "relu"),
      //   perceptron["new neuron"](3, 0.001, "relu"),
      //   perceptron["new neuron"](3, 0.001, "relu")
      //),
      //list(
      //   perceptron["new neuron"](4, 0.001, "relu"),
      //   perceptron["new neuron"](4, 0.001, "relu")
      //)
   )).
   model:add("outputLayer", list(
      perceptron["new neuron"](3, 0.01, "sigmoid")
   )).
}

wait 0.

local targetAlt is 30.
local selfTrain is 0.
local throttValue is 0.
lock steering to up.
lock throttle to throttValue.
if ship:availablethrust <= 0 stage.
local startTime is time:seconds.
local flameout is false.
until false {
  print "training" at(0, 0).
  
   local maxAccel is ship:availablethrust()/ship:mass - (ship:body:mu/((alt:radar+ship:body:radius)^2)).
   local normalizedInput is list(
     list(ship:verticalspeed),
     list(targetAlt-alt:radar),
     list(maxAccel) // acceleration
  ).
  set nOutput to perceptron["training supervisor"](
     // Output supervisor
     {
         //declare function throttleFunction {
         //   declare parameter targetAltitude.
         //   
         //   local currentG is (ship:body:mu/((alt:radar+ship:body:radius)^2)).
         //   local maxAccel is ship:availablethrust()/ship:mass. // Lose 1 g for hover
         //   local throttMaxGees is maxAccel/currentG -1.

         //   local pitchLimit is arccos(currentG/max(currentG, maxAccel)).

         //   local gLimit is 1.
         //   local outputMax is choose max(vang(up:forevector, ship:facing:forevector)/pitchLimit, (1+gLimit)/throttMaxGees) if ship:availablethrust() > 0 else 0.
         //   //local outputMin is choose currentG/maxAccel if ship:verticalspeed < 0 else 0.  // Minimum 0.5 G
         //   local speedLimit is choose sqrt(abs(alt:radar - targetAltitude)*currentG) if alt:radar < targetAltitude else -sqrt(abs(alt:radar - targetAltitude)*currentG).
         //   local vSpeedError is 0.
         //   set vSpeedError to ship:verticalspeed - speedLimit.
         //   local vSpeedSigmoid is min(outputMax, -vSpeedError/sqrt(currentG+vSpeedError^2)).
         //   return vSpeedSigmoid.
         //}
        if targetAlt - alt:radar > 1 {
           // Below target
           //set selfTrain to 1-ship:verticalspeed/10.
           if ship:verticalspeed > 5 set selfTrain to selfTrain - 0.001.
           else if ship:verticalspeed < 1 set selfTrain to selfTrain + 0.001.
        } else if targetAlt - alt:radar < -1 {
           // Above target
           //set selfTrain to (-ship:verticalspeed)/10 - abs(targetAlt - alt:radar)/30.
           if ship:verticalspeed > -1 set selfTrain to selfTrain - 0.001.
           else if ship:verticalspeed < -5 set selfTrain to selfTrain + 0.001.
        }
        //set selfTrain to throttleFunction(targetAlt).
        set selfTrain to selfTrain.
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
        if ship:verticalspeed < -20 or alt:radar > 1000 or flameout or vang(ship:facing:forevector, up:forevector) > 90 or missiontime > 15*60 {
           perceptron["save model"](model["inputLayer"], model["hiddenLayers"], model["outputLayer"], "0:/models/hoverflow.json").
           wait 1.
           //kuniverse:pause().
           kuniverse:reverttolaunch().
        }
     }
   ).
  
  set throttValue to nOutput.
  //set throttValue to selfTrain.
  //set throttValue to min(nOutput, selfTrain).

  //print "input:"+normalizedInput at(0, 4).
  print "targetAlt: "+targetAlt at(0, 6).
  print "alt:radar: "+alt:radar at(0, 7).
  print "selfTrain: "+selfTrain+"                      " at(0, 9).
  print "networkOutput: "+ nOutput+"                   " at(0, 10).
  print "input: "+normalizedInput at(0, 12).
  if time:seconds > startTime + 30 {
    set startTime to time:seconds.
    set targetAlt to random()*100+5.
  }
  print "countdown: "+(startTime+30-time:seconds) at(0, 2).

}
