{
   global perceptron is lexicon().


   perceptron:add("new neuron", {
      declare parameter inputSize.
      declare parameter learningRate.
      declare parameter actFunction is "relu".

      local neuron is lexicon().
      local weights is list().
      local bias is random().
      local activationFunction is actFunction.
      from {local i is 0.} until i >= inputSize step {set i to i+1.} do{
         weights:add(random()).
      }
      
      declare function activation {
         declare parameter input.
         if activationFunction = "relu" return max(0, input).
         else if activationFunction = "sigmoid" return input/sqrt(1+input^2).
      }

      declare function summation {
         declare parameter weights.
         declare parameter inputs.

         local z is 0.
         from {local i is 0.} until i > inputs:length-1 step {set i to i+1.} do {
           set z to z + weights[i]*inputs[i]. 
         }
         set z to z + bias.
         return z.
      }

      neuron:add("evaluate", {
         declare parameter inputs.
         print bias at (0, 14).
         print weights at(0, 15).
         return activation(summation(weights, inputs)).
      }).

      neuron:add("train", {
         declare parameter inputs.
         declare parameter trainValue.

         local sumOfInputs is 0.
         local sumOfWeights is 0.
         from {local i is 0.} until i > weights:length-1 step {set i to i+1.} do {
            set sumOfInputs to sumOfInputs + inputs[i].
            set sumOfWeights to sumOfWeights + weights[i].
         }

         local current is activation(summation(weights, inputs)). 
         local delta is current - trainValue.
         print "current: "+current at(0, 17).
         print "delta: "+delta at(0, 18).
         set sumOfWeights to sumOfWeights + bias.

         local backPropInputs is list().
         local outputWOBias is 0.
         from {local i is 0.} until i > weights:length-1 step {set i to i+1.} do {
            set weights[i] to weights[i]+delta*(weights[i]/sumOfWeights)*learningRate.
            set outputWOBias to outputWOBias + inputs[i]*weights[i].
            //set backPropInputs to inputs[i] - 
         }
         set outputWOBias to activation(outputWOBias).
         set bias to bias+(outputWOBias-trainValue)*learningRate/sumOfWeights.

      }).
      
      return neuron.
   }).
   
}

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

local neuron is perceptron["new neuron"](2, 0.001, "sigmoid").  // Inputs: ship:verticalspeed, alt:radar
local targetAlt is 30.
local tValue is max(0, throttleFunction(targetAlt)).
local nOutput is 0.
//local thrott is 0.
lock steering to up.
lock throttle to nOutput.
stage.
until targetAlt <= 1 {
  neuron["train"](list(ship:verticalspeed, alt:radar-targetAlt), tValue).
  set nOutput to min(neuron["evaluate"](list(ship:verticalspeed, alt:radar-targetAlt)), tValue).

  print "targetAlt: "+targetAlt at(0, 7).
  print "alt:radar: "+alt:radar at(0, 8).
  print "tValue: "+tValue at(0, 9).
  print "neuronOutput: "+ nOutput+"                   " at(0, 10).
  set tValue to throttleFunction(targetAlt).
  if abs(alt:radar - targetAlt) < 1 set targetAlt to targetAlt - 0.5.
}
set targetAlt to 30.
until false {
  set nOutput to neuron["evaluate"](list(ship:verticalspeed, alt:radar-targetAlt)).
  print "neuronOutput: "+ nOutput+"                   " at(0, 10).
}
