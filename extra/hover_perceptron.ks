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
         else if activationFunction = "sym_sigmoid" return 2/(1+constant:e^(-max(0.0000001, input))) - 1.
         else if activationFunction = "sigmoid" return 1/(1+constant:e^(-max(0.0000001, input))).
         else if activationFunction = "linear" return input.
         else if activationFunction = "square" return max(0.0000001, min(9999999, input)^2).
         else if activationFunction = "sqrt" return sqrt(abs(input)).
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
            if abs(weights[i]) > 1000000 or abs(weights[i]) < 0.000001 set weights[i] to random().
            set outputWOBias to outputWOBias + inputs[i]*weights[i].
            backPropInputs:add(inputs[i] + deltaWeight*(inputs[i]/sumOfInputs)).
         }
         set outputWOBias to activation(outputWOBias).
         set bias to bias+(outputWOBias-trainValue)*learningRate/sumOfWeights.
         if abs(bias) > 1000000 or abs(bias) < 0.000001 set bias to random().

         return backPropInputs.

      }).
      
      return neuron.
   }).


   declare function trainDenseLayer {
      declare parameter inputs. // list. Multiple inputs for each node, but the same inputs for each node. 
      declare parameter layer.
      declare parameter trainValues. // list. One output for each node.

      local backPropValues is list().
      from {local i is 0.} until i > layer:length-1 step {set i to i+1.} do {
         local backP is layer[i]["train"](inputs, trainValues[i]).
         if i > 0 { // Averages the back prop values from all the hidden layer nodes into one back prop list
            from {local j is 0.} until j > backPropValues:length-1 step {set j to j+1.} do {
               set backPropValues[j] to backPropValues[j] + backP[j].
            }
         } else set backPropValues to backP.
      }
      // Final part of averaging operation
      from {local i is 0.} until i > backPropValues:length-1 step {set i to i+1.} do {
         set backPropValues[i] to backPropValues[i]/inputs:length.
      }

      return backPropValues.
   }
   perceptron:add("train network", {
      declare parameter inputValues. // List of lists.  One list for every input node.
      declare parameter trainValue.
      declare parameter inputNeurons.
      declare parameter hiddenLayer.
      declare parameter outputNeuron.

      local intermVal is list().
      from {local i is 0.} until i > inputNeurons:length-1 step {set i to i+1.} do {
         intermVal:add(inputNeurons[i]["evaluate"](inputValues[i])).
      }

      local intermVal2 is list().
      if hiddenLayer:typename = "List" {
         from {local i is 0.} until i > hiddenLayer:length-1 step {set i to i+1.} do {
            intermVal2:add(hiddenLayer[i]["evaluate"](intermVal)).
         }
      }
      
      local backProp is list().
      if hiddenLayer:typename = "List" {
         set backProp to outputNeuron["train"](intermVal2, trainValue).
         set backProp to trainDenseLayer(intermVal, hiddenLayer, backProp).
      } else set backProp to outputNeuron["train"](intermVal, trainValue).
      from {local i is 0.} until i > inputNeurons:length-1 step {set i to i+1.} do {
         inputNeurons[i]["train"](inputValues[i], backProp[i]).
      }
   }).
   
}


set config:ipu to 2000.
local inputLayer is list(
   perceptron["new neuron"](2, 0.01, "relu"),  // Inputs: ship:verticalspeed
   perceptron["new neuron"](2, 0.01, "relu")  // Inputs: alt:radar - targetAlt
).
local hiddenLayer is list(
   perceptron["new neuron"](2, 0.001, "relu"),
   perceptron["new neuron"](2, 0.001, "relu"),
   perceptron["new neuron"](2, 0.001, "relu")
).
local outputNeuron is perceptron["new neuron"](3, 0.001, "sym_sigmoid"). 

local targetAlt is 20.
local selfTrain is 0.
local backProp is list().
local nOutput is 0.
local throttValue is 0.
lock steering to up.
lock throttle to throttValue.
if ship:availablethrust <= 0 stage.
local startTime is time:seconds.
until false {
  print "training" at(0, 0).
  
  local normalizedInput is list(
     list(ship:verticalspeed, (targetAlt-alt:radar)),
     list((targetAlt-alt:radar), ship:verticalspeed)
  ).
  perceptron["train network"](
     normalizedInput,
     selfTrain, 
     inputLayer, 
     hiddenLayer,
     outputNeuron
  ).
  
  local layerOutputs is list().
  from {local i is 0.} until i > inputLayer:length - 1 step {set i to i+1.} do {
     layerOutputs:add(inputLayer[i]["evaluate"](normalizedInput[i])).
  }
  local hiddenLayerOutputs is list().
  from {local i is 0.} until i > hiddenLayer:length - 1 step {set i to i+1.} do {
     hiddenLayerOutputs:add(hiddenLayer[i]["evaluate"](layerOutputs)).
  }

  set nOutput to outputNeuron["evaluate"](hiddenLayerOutputs).
  //set nOutput to outputNeuron["evaluate"](layerOutputs).
  set error to (targetAlt - alt:radar).
  set width to 2.
  set selfTrain to (error/width)/(1+(error/(2*width))^2).
  set selfTrain to nOutput + selfTrain.
  set throttValue to selfTrain.
  // Safety
  if alt:radar > targetAlt +1 set throttValue to 0.5.
  if ship:verticalspeed < -10 set throttValue to max(0.6, throttValue*1.5).
  set selfTrain to throttValue.
  

  print "targetAlt: "+targetAlt at(0, 6).
  print "alt:radar: "+alt:radar at(0, 7).
  print "selfTrain: "+selfTrain+"                      " at(0, 9).
  print "networkOutput: "+ nOutput+"                   " at(0, 10).
  inputLayer[0]["print weights"](12).
  inputLayer[1]["print weights"](15).
  hiddenLayer[0]["print weights"](18).
  hiddenLayer[1]["print weights"](21).
  hiddenLayer[2]["print weights"](24).
  outputNeuron["print weights"](27).
  if time:seconds > startTime + 30 {
    set startTime to time:seconds.
    set targetAlt to random()*25.
  }
  print "targetAlt: "+targetAlt at(0, 1).
  print "countdown: "+(startTime+30-time:seconds) at(0, 2).
}
