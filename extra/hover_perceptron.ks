{
   global perceptron is lexicon().


   perceptron:add("new neuron", {
      declare parameter inputSize.
      declare parameter learningRate.
      declare parameter actFunction is "relu".
      declare parameter w is list().
      declare parameter b is random().

      local neuron is lexicon().
      local weights is w.
      local bias is b.
      local activationFunction is actFunction.

      if weights:length <> inputSize {
         from {local i is 0.} until i >= inputSize step {set i to i+1.} do{
            weights:add(random()).
         }
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

      neuron:add("serialize", {
         local output is lexicon().
         output:add("inputSize", inputSize).
         output:add("learningRate", learningRate).
         output:add("activationFunction", activationFunction).
         output:add("weights", weights).
         output:add("bias", bias).

         return output.
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
            if abs(weights[i]) > 1000000 or 
               abs(weights[i]) < 0.000001 
               //or mod(floor(time:seconds)+i, floor(random()*100+1)) = 0 
               set weights[i] to random().
            set outputWOBias to outputWOBias + inputs[i]*weights[i].
            backPropInputs:add(inputs[i] + deltaWeight*(inputs[i]/sumOfInputs)).
         }
         set outputWOBias to activation(outputWOBias).
         set bias to bias+(outputWOBias-trainValue)*learningRate/sumOfWeights.
         if abs(bias) > 1000000 or abs(bias) < 0.000001 
         //or mod(floor(time:seconds), floor(random()*101+1)) = 0 
            set bias to random().

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
      declare parameter trainValues.
      declare parameter inputLayer.
      declare parameter hiddenLayers.
      declare parameter outputLayer.

      // Evaluate Input layer
      local intermVal is list().
      from {local i is 0.} until i > inputLayer:length-1 step {set i to i+1.} do {
         intermVal:add(inputLayer[i]["evaluate"](inputValues[i])).
      }

      // Evaluate hidden layers
      local hiddenLayerIntermVals is list().
      from {local i is 0.} until i > hiddenLayers:length-1 step {set i to i+1.} do {
         local layerOutputs is list().
         from {local j is 0.} until j > hiddenLayers[i]:length-1 step {set j to j+1.} do {
            if i = 0 layerOutputs:add(hiddenLayers[i][j]["evaluate"](intermVal)).
            else layerOutputs:add(hiddenLayers[i][j]["evaluate"](hiddenLayerIntermVals[i-1])).
         }
         hiddenLayerIntermVals:add(layerOutputs).
      }

      // Train output layer and begin back propagating 
      local backProp is list().
      if hiddenLayers:length = 0 set backProp to trainDenseLayer(intermVal, outputLayer, trainValues).
      else set backProp to trainDenseLayer(hiddenLayerIntermVals[hiddenLayerIntermVals:length-1], outputLayer, trainValues).
      local oldOutputs is backProp.

      // Back propagate through hidden layers
      from {local i is hiddenLayers:length-1.} until i < 0 step {set i to i -1.} do {
         if i = 0 set backProp to trainDenseLayer(intermVal, hiddenLayers[i], backProp).
         else set backProp to trainDenseLayer(hiddenLayerIntermVals[i-1], hiddenLayers[i], backProp).
      }

      // Train input layer
      from {local i is 0.} until i > inputLayer:length-1 step {set i to i+1.} do {
         inputLayer[i]["train"](inputValues[i], backProp[i]).
      }

      return oldOutputs.
   }).

   perceptron:add("evaluate network", {
      declare parameter inputValues.
      declare parameter inputLayer.
      declare parameter hiddenLayers.
      declare parameter outputLayer.

      // Evaluate Input layer
      local intermVal is list().
      from {local i is 0.} until i > inputLayer:length-1 step {set i to i+1.} do {
         intermVal:add(inputLayer[i]["evaluate"](inputValues[i])).
      }

      // Evaluate hidden layers
      local hiddenLayerIntermVals is list().
      from {local i is 0.} until i > hiddenLayers:length-1 step {set i to i+1.} do {
         local layerOutputs is list().
         from {local j is 0.} until j > hiddenLayers[i]:length-1 step {set j to j+1.} do {
            if i = 0 layerOutputs:add(hiddenLayers[i][j]["evaluate"](intermVal)).
            else layerOutputs:add(hiddenLayers[i][j]["evaluate"](hiddenLayerIntermVals[i-1])).
         }
         hiddenLayerIntermVals:add(layerOutputs).
      }

      // Evaluate Output layer
      local intermVal2 is list().
      if hiddenLayers:length = 0 set intermVal2 to intermVal.
      else set intermVal2 to hiddenLayerIntermVals[hiddenLayerIntermVals:length-1].
      local output is list().
      from {local i is 0.} until i > outputLayer:length-1 step {set i to i+1.} do {
         output:add(outputLayer[i]["evaluate"](intermVal2)).
      }

      return output.

   }).

   perceptron:add("normalize input", {
      declare parameter top.
      declare parameter bottom.
      declare parameter value.

      local normalizedValue is max(bottom, min(top, value)).

      return (normalizedValue-bottom)/(top-bottom).
   }).

   perceptron:add("save model", {
      declare parameter inputLayer.
      declare parameter hiddenLayers.
      declare parameter outputLayer.
      declare parameter outFile.

      local output is lexicon().
      local currentList is list().
      for n in inputLayer currentList:add(n:serialize()).
      output:add("inputLayer", currentList).
      set currentList to list().
      for l in hiddenLayers {
         local layerlist is list().
         for n in l layerlist:add(n:serialize()).
         currentList:add(layerlist).
      }
      output:add("hiddenLayers", currentList).
      set currentList to list().
      for n in outputLayer currentList:add(n:serialize()).
      output:add("outputLayer", currentList).
      
      writeJson(output, outFile).
   }).

   perceptron:add("load model", {
      declare parameter inFile.
      local input is readJson(inFile).
      local model is lexicon().
      local currentList is list().
      for n in input["inputLayer"] currentList:add(perceptron["new neuron"](n["inputSize"], n["learningRate"], n["activationFunction"], n["weights"], n["bias"])).
      model:add("inputLayer", currentList).
      
      set currentList to list().
      for l in input["hiddenLayers"] {
         local layer is list().
         for n in l layer:add(perceptron["new neuron"](n["inputSize"], n["learningRate"], n["activationFunction"], n["weights"], n["bias"])).
         currentList:add(layer).
      }
      model:add("hiddenLayers", currentList).

      set currentList to list().
      for n in input["outputLayer"] currentList:add(perceptron["new neuron"](n["inputSize"], n["learningRate"], n["activationFunction"], n["weights"], n["bias"])).
      model:add("outputLayer", currentList).

      return model.
   }).
   
}


set config:ipu to 2000.
local model is lexicon().
local nOutput is 0.
if exists("0:/mlp.json") {
   set model to perceptron["load model"]("0:/mlp.json"). 
   //deletepath("0:/mlp.json").
} else {
   model:add("inputLayer", list(
      perceptron["new neuron"](3, 0.001, "linear"),  // Inputs: ship:verticalspeed
      perceptron["new neuron"](3, 0.001, "linear"),  // Inputs: alt:radar - targetAlt
      perceptron["new neuron"](3, 0.001, "linear")    // nOutput
   )).
   model:add("hiddenLayers", list(list(
      perceptron["new neuron"](3, 0.001, "relu"),
      perceptron["new neuron"](3, 0.001, "relu"),
      perceptron["new neuron"](3, 0.001, "relu")
   ))).
   model:add("outputLayer", list(
      perceptron["new neuron"](3, 0.001, "sigmoid")
   )).
}

wait 5.

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
  
  if targetAlt - alt:radar > 1 {
     // Below target
     if ship:verticalspeed > 10 set selfTrain to selfTrain - 0.001.
     else if ship:verticalspeed < 1 set selfTrain to selfTrain + 0.1.
  } else if targetAlt - alt:radar < -1 {
    // Above target
     if ship:verticalspeed > -1 set selfTrain to selfTrain - 0.1.
     else if ship:verticalspeed < -10 set selfTrain to selfTrain + 0.001.
  }
  local normalizedInput is list(
     list(perceptron["normalize input"](10, -10, ship:verticalspeed), perceptron["normalize input"](30, -30, (targetAlt-alt:radar)), nOutput),
     list(perceptron["normalize input"](10, -10, ship:verticalspeed), perceptron["normalize input"](30, -30, (targetAlt-alt:radar)), nOutput),
     list(perceptron["normalize input"](10, -10, ship:verticalspeed), perceptron["normalize input"](30, -30, (targetAlt-alt:radar)), nOutput)
  ).
  set nOutput to perceptron["train network"](
     normalizedInput,
     list(nOutput+selfTrain), 
     model["inputLayer"], 
     model["hiddenLayers"],
     model["outputLayer"]
  )[0].
  
  set throttValue to nOutput.

  //print "input:"+normalizedInput at(0, 4).
  print "targetAlt: "+targetAlt at(0, 6).
  print "alt:radar: "+alt:radar at(0, 7).
  print "selfTrain: "+selfTrain+"                      " at(0, 9).
  print "networkOutput: "+ nOutput+"                   " at(0, 10).
  model["inputLayer"][0]["print weights"](12).
  model["inputLayer"][1]["print weights"](15).
  model["hiddenLayers"][0][0]["print weights"](18).
  model["hiddenLayers"][0][1]["print weights"](21).
  model["hiddenLayers"][0][2]["print weights"](24).
  model["outputLayer"][0]["print weights"](27).
  if time:seconds > startTime + 30 {
    set startTime to time:seconds.
    set targetAlt to random()*100.
    list Engines in engList.
    for eng in engList if eng:flameout set flameout to true. 
  }
  print "targetAlt: "+targetAlt at(0, 1).
  print "countdown: "+(startTime+30-time:seconds) at(0, 2).

  // Revert
  if alt:radar > 500 or flameout or vang(ship:facing:forevector, up:forevector) > 90 {
     perceptron["save model"](model["inputLayer"], model["hiddenLayers"], model["outputLayer"], "0:/mlp.json").
     wait 1.
     //kuniverse:pause().
     kuniverse:reverttolaunch().
  }
}
