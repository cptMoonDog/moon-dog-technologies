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
         else if activationFunction = "relu_sigmoid" return max(0, input/sqrt(1+input^2)).
         else if activationFunction = "linear" return input.
         else if activationFunction = "square" return max(0.0000001, min(9999999, input)^2).
         else if activationFunction = "cube" return max(0.0000001, min(9999999, input))^3.
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
         return activation(summation(weights, inputs)).
      }).

      neuron:add("print weights", {
         declare parameter row.
         print "Weights: "+weights+"                              " at(0, row).
         print "Bias: "+bias+"                     " at(0, row+1).
      }).

      neuron:add("train", {
         declare parameter inputs.
         declare parameter trainValue.

         local sumOfInputs is 0.
         local sumOfWeights is 0.
         //print "inputs: "+inputs at(0, 22).
         from {local i is 0.} until i > weights:length-1 step {set i to i+1.} do {
            set sumOfInputs to sumOfInputs + inputs[i].
            //print "sumOfInputs: "+sumOfInputs at(0, 20).
            set sumOfWeights to sumOfWeights + weights[i].
         }
         if sumOfInputs = 0 set sumOfInputs to 0.000001.

         local current is activation(summation(weights, inputs)). 
         local delta is current - trainValue.
         set sumOfWeights to sumOfWeights + bias.

         local backPropInputs is list().
         local outputWOBias is 0.
         local deltaWeight is 0.
         from {local i is 0.} until i > weights:length-1 step {set i to i+1.} do {
            set deltaWeight to delta*(weights[i]/sumOfWeights)*learningRate.
            set weights[i] to weights[i]+deltaWeight.
            set outputWOBias to outputWOBias + inputs[i]*weights[i].
            backPropInputs:add(inputs[i] + deltaWeight*(inputs[i]/sumOfInputs)*learningRate).
         }
         set outputWOBias to activation(outputWOBias).
         set bias to bias+(outputWOBias-trainValue)*learningRate/sumOfWeights.

         return backPropInputs.

      }).
      
      return neuron.
   }).

   perceptron:add("train network", {
      declare parameter inputValues.
      declare parameter trainValue.
      declare parameter inputNeuron1.
      declare parameter inputNeuron2.
      declare parameter outputNeuron.

      local intermVal is list().
      intermVal:add(inputNeuron1["evaluate"](inputValues)).
      intermVal:add(inputNeuron2["evaluate"](inputValues)).
      //print "inputValues: "+inputValues at(0,16).
      //print "intermVal: "+intermVal at(0, 18).
      local backProp is list().
      set backProp to outputNeuron["train"](intermVal, trainValue).
      //print "backProp: "+backProp at(0, 19).
      local average is 0.
      for x in backProp set average to average + x.
      set average to average/backProp:length.
      //print "average: "+average at(0, 17).
      inputNeuron1["train"](inputValues, average).
      inputNeuron2["train"](inputValues, average).
   }).
   
}

declare function throttleFunction {
   declare parameter targetAltitude.
   
   local currentG is (ship:body:mu/((alt:radar+ship:body:radius)^2)).
   local maxAccel is ship:availablethrust()/ship:mass. // Lose 1 g for hover
   local throttMaxGees is maxAccel/currentG -1.

   local pitchLimit is arccos(currentG/max(currentG, maxAccel)).

   local gLimit is 0.5.
   local outputMax is choose max(vang(up:forevector, ship:facing:forevector)/pitchLimit, (1+gLimit)/throttMaxGees) if ship:availablethrust() > 0 else 0.
   local outputMin is gLimit/throttMaxGees. // Minimum 0.5 G
   local speedLimit is choose sqrt(abs(alt:radar - targetAltitude)*currentG) if alt:radar < targetAltitude else -sqrt(abs(alt:radar - targetAltitude)*currentG).
   local vSpeedError is 0.
   set vSpeedError to ship:verticalspeed - speedLimit.
   local vSpeedSigmoid is min(outputMax, -vSpeedError/sqrt(currentG+vSpeedError^2)).
   return vSpeedSigmoid.
}

set config:ipu to 2000.
local neuronInput1 is perceptron["new neuron"](2, 0.001, "linear").  // Inputs: ship:verticalspeed, alt:radar
local neuronInput2 is perceptron["new neuron"](2, 0.001, "linear").  // Inputs: ship:verticalspeed, alt:radar 
local neuronOutput is perceptron["new neuron"](2, 0.001, "sigmoid"). 
local targetAlt is 30.
local tValue is max(0, throttleFunction(targetAlt)).
local backProp is list().
local nOutput is 0.
local throttValue is 0.
lock steering to up.
lock throttle to throttValue.
if ship:availablethrust <= 0 stage.
local startTime is time:seconds.
local trainingStartTime is time:seconds.
until targetAlt < 1.75 {
  print "training" at(0, 0).
  
  perceptron["train network"](list(ship:verticalspeed, alt:radar-targetAlt), tValue, neuronInput1, neuronInput2, neuronOutput).
  
  set nOutput to neuronOutput["evaluate"](list(
     neuronInput1["evaluate"](list(ship:verticalspeed, alt:radar-targetAlt)),
     //neuronInput1["evaluate"](list(ship:verticalspeed)),
     neuronInput2["evaluate"](list(ship:verticalspeed, alt:radar-targetAlt))
     //neuronInput2["evaluate"](list(alt:radar-targetAlt))
   )).
  set throttValue to min(nOutput, tValue).

  print "targetAlt: "+targetAlt at(0, 7).
  print "alt:radar: "+alt:radar at(0, 8).
  print "tValue: "+tValue at(0, 9).
  print "networkOutput: "+ nOutput+"                   " at(0, 10).
  neuronInput1["print weights"](12).
  neuronInput2["print weights"](15).
  neuronOutput["print weights"](18).
  set tValue to throttleFunction(targetAlt).
  if abs(alt:radar - targetAlt) < 1 and time:seconds > trainingStartTime + 60 set targetAlt to targetAlt - 0.25.
  if time:seconds > startTime + 15 {
    set startTime to time:seconds.
    set targetAlt to random()*100+2.
  }
  print "targetAlt: "+targetAlt at(0, 1).
  print "countdown: "+(startTime+15-time:seconds) at(0, 2).
}
set targetAlt to 30.
set startTime to time:seconds.
local flag is false.
until flag {
  print "testing         " at(0, 0).
  set nOutput to neuronOutput["evaluate"](list(
  neuronInput1["evaluate"](list(ship:verticalspeed, alt:radar-targetAlt)),
  neuronInput2["evaluate"](list(ship:verticalspeed, alt:radar-targetAlt))
  )).
  set throttValue to nOutput.
  print "neuronOutput: "+ nOutput+"                   " at(0, 10).
  if time:seconds > startTime + 15 {
    set startTime to time:seconds.
    set targetAlt to random()*100.
    print "targetAlt: "+targetAlt at(0, 1).
  }
 print "countdown: "+(startTime+15-time:seconds) at(0, 2).
 if alt:radar > 200 set flag to true.
}
