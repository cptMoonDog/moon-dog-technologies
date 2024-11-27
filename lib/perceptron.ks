// WernerFlow?  KerboTorch?  Whatever you want to call it, it is my gift to you.
// A very simple neural network library written in KerboScript for kOS.

// Usage:
//    perceptron["training supervisor"]([OUTPUT SUPERVISOR], [SESSION MANAGER])
//       Accepts two delegates to manage your training session.  The first should manage the training values trained against, and the second should handle the training session, saving the model, reverting to launch, etc.
//       Returns the output of the first delegate.
// 
//       Example:
//          
//          set nOutput to perceptron["training supervisor"](
//             // Output supervisor
//             {
//                if targetAlt - alt:radar > 1 {
//                   // Below target
//                   if ship:verticalspeed > 10 set selfTrain to selfTrain - 0.001.
//                   else if ship:verticalspeed < 1 set selfTrain to selfTrain + 0.1.
//                } else if targetAlt - alt:radar < -1 {
//                  // Above target
//                   if ship:verticalspeed > -1 set selfTrain to selfTrain - 0.1.
//                   else if ship:verticalspeed < -10 set selfTrain to selfTrain + 0.001.
//                }
//                set selfTrain to min(1, max(-1, selfTrain)).
//                set nOutput to perceptron["train network"](
//                   normalizedInput,
//                   list(nOutput+selfTrain), 
//                   model["inputLayer"], 
//                   model["hiddenLayers"],
//                   model["outputLayer"]
//                )[0].
//        
//                return nOutput.
//             }, 
//             // Session supervisor
//             {
//                list Engines in engList.
//                for eng in engList if eng:flameout set flameout to true. 
//                // Revert
//                if alt:radar > 2000 or flameout or vang(ship:facing:forevector, up:forevector) > 90 {
//                   perceptron["save model"](model["inputLayer"], model["hiddenLayers"], model["outputLayer"], "0:/mlp.json").
//                   wait 1.
//                   //kuniverse:pause().
//                   kuniverse:reverttolaunch().
//                }
//             }
//           ).

//   perceptron["load model"]([FILE])
//      Loads a model from the given json file
//   
//   perceptron["save model"]([INPUT LAYER], [HIDDEN LAYERS], [OUTPUT LAYER], [FILE])
//      Saves a model to the given file
//      Example model definition:
//        local model is lexicon().
//        if exists("0:/mlp.json") {
//           set model to perceptron["load model"]("0:/mlp.json"). 
//        } else {
//           model:add("inputLayer", list(
//              perceptron["new neuron"](1, 0.001, "relu"),  // ship:verticalspeed
//              perceptron["new neuron"](1, 0.001, "relu")   // targetAlt - alt:radar
//           )).
//           model:add("hiddenLayers", list(
//              list(
//                 perceptron["new neuron"](2, 0.001, "relu"),
//                 perceptron["new neuron"](2, 0.001, "relu"),
//                 perceptron["new neuron"](2, 0.001, "relu")
//              ),
//              list(
//                 perceptron["new neuron"](3, 0.001, "relu"),
//                 perceptron["new neuron"](3, 0.001, "relu")
//              )
//           )).
//           model:add("outputLayer", list(
//              perceptron["new neuron"](2, 0.001, "sigmoid")
//           )).
//        }
// 
//   perceptron["normalize input"]([UPPER BOUND], [LOWER BOUND], [VALUE])
//      It is very important to normalize your input.  Training does not work well otherwise.
//  
//   perceptron["train network"]([INPUT VALUES], [TRAIN VALUES], [INPUT LAYER], [HIDDEN LAYERS], [OUTPUT LAYER])
//     Trains the network using the provided inputs and training data.
//     Returns the output of the network from before training.  (Improves performance, by not evaluating the network a third time.)
//
//   perceptron["evaluate network"]([INPUT VALUES], [INPUT LAYER], [HIDDEN LAYERS], [OUTPUT LAYER]))
//      If you are confident that the network is sufficiently trained, you can use it with this function.
//      Returns network output for the given inputs.
//
//   perceptron["new neuron"]([NUMBER OF INPUTS], [LEARNING RATE], [ACTIVATION FUNCTION])    
//      Used to create network nodes.
//      Returns a "neuron" closure.

{
   global perceptron is lexicon().


   perceptron:add("new neuron", {
      declare parameter inputSize.
      declare parameter learningRate.
      declare parameter actFunction is "relu".
      declare parameter b is random().
      declare parameter w is list().

      local neuron is lexicon().
      local weights is w.
      local bias is b.
      local activationFunction is actFunction.

      if weights:length <> inputSize {
         from {local i is 0.} until i >= inputSize step {set i to i+1.} do{
            weights:add(random()*2-1). // Weights can be negative
         }
      }
      
      declare function activation {
         declare parameter input.
         if activationFunction = "relu" return max(0, input).
         else if activationFunction = "sigmoid" return 1/(1+constant:e^(-min(100, max(-100, input)))).
         else if activationFunction = "square" return input*input.
         else if activationFunction = "sine" return sin(input).
         else if activationFunction = "linear" return input.
         else return input.
      }

      declare function summation {
         declare parameter weights.
         declare parameter inputs.

         local z is 0.
         from {local i is 0.} until i > inputs:length-1 step {set i to i+1.} do {
           set z to z + weights[i]*inputs[i]. 
         }
         set z to z + bias*1. // Bias is trainable.  Not always 1, but the corresponding vector input is always 1.
         return z.
      }

      declare function eval {
         declare parameter inputs.
         return activation(summation(weights, inputs)).
      }
      neuron:add("evaluate", eval@).

      neuron:add("print weights", {
         declare parameter row.
         print "Weights: "+weights+"                              " at(0, row+1).
      }).

      neuron:add("serialize", {
         local output is lexicon().
         output:add("inputSize", inputSize).
         output:add("learningRate", learningRate).
         output:add("activationFunction", activationFunction).
         output:add("bias", bias).
         output:add("weights", weights).

         return output.
      }).

      neuron:add("train", {
         declare parameter inputs.
         declare parameter trainValue.

         if inputs:length = weights:length {
            local current is eval(inputs).
            local delta is (trainValue - current).

            local backPropError is list().
            from {local i is 0.} until i > weights:length-1 step {set i to i+1.} do {
               set weights[i] to weights[i]+delta*inputs[i]*learningRate.
               backPropError:add(min(1000000, max(-1000000, weights[i]*delta))).  // The error back propagates
               if abs(weights[i]) > 1000000 set weights[i] to random()*2-1.
               else if abs(weights[i]) < 0.0000001 set weights[i] to 0.
            }
            set bias to bias + delta*learningRate. // The vector input for the bias is assumed 1.
            if abs(bias) > 1000000 set bias to random()*2-1.
            else if abs(bias) < 0.0000001 set bias to 0.


            return backPropError.
         } else {
            print "weights("+weights:length+") and inputs("+inputs:length+") length mismatch".
            shutdown.
         }

      }).
      
      return neuron.
   }).
   
   declare function trainDenseLayer {
      declare parameter inputs. // list. Multiple inputs for each node, but the same inputs for each node. 
      declare parameter layer.
      declare parameter backProp. // list. One output for each node.
      declare parameter errorFunction is rootMeanSquaredError@.
      declare parameter isError is true. 

      local trainValues is backProp.
      if isError {
      // For the output layer, we train against known values, for prior layers, we train against the prior output plus the received error.
         from {local i is 0.} until i > trainValues:length-1 step {set i to i+1.} do {
            local current is layer[i]["evaluate"](inputs).
            set trainValues[i] to current + trainValues[i].
         }
            
      }
      local backPropErrorRaw is list().
      from {local i is 0.} until i > layer:length-1 step {set i to i+1.} do {
         backPropErrorRaw:add(layer[i]["train"](inputs, trainValues[i])).
      }
      return errorFunction(backPropErrorRaw, inputs:length).
   }

   declare function rootMeanSquaredError {
      declare parameter errors.
      declare parameter length.

      local output is list().
      from {local i is 0.} until i > length-1 step {set i to i+1.} do {
         local workingVal is 0.
         from {local j is 0.} until j > errors:length-1 step {set j to j+1.} do {
            set workingVal to workingVal + errors[j][i]*abs(errors[j][i]).
         }
         local dirComp is 1.
         if workingVal = 0 set dirComp to 1.
         else set dirComp to (workingVal/abs(workingVal)).

         set workingVal to sqrt(abs(workingVal/errors:length))*dirComp.
         output:add(workingVal).
      }
      return output.
   }
   declare function meanSquaredError {
      declare parameter errors.
      declare parameter length.

      local output is list().
      from {local i is 0.} until i > length-1 step {set i to i+1.} do {
         local workingVal is 0.
         from {local j is 0.} until j > errors:length-1 step {set j to j+1.} do {
            set workingVal to workingVal + errors[j][i]*abs(errors[j][i]).
         }

         set workingVal to workingVal/errors:length.
         output:add(workingVal).
      }
      return output.
   }
   declare function meanAbsoluteError {
      declare parameter errors.
      declare parameter length.

      local output is list().
      from {local i is 0.} until i > length-1 step {set i to i+1.} do {
         local workingVal is 0.
         from {local j is 0.} until j > errors:length-1 step {set j to j+1.} do {
            set workingVal to workingVal + errors[j][i].
         }
         set workingVal to workingVal/errors:length.
         output:add(workingVal).
      }
      return output.
   }

   perceptron:add("train network", {
      declare parameter inputValues. // List of lists.  One list for every input node.
      declare parameter trainValues.
      declare parameter inputLayer.
      declare parameter hiddenLayers.
      declare parameter outputLayer.

      if outputLayer:length = 0 {
         local output is list().
         from {local i is 0.} until i > inputLayer:length - 1 step {set i to i+1.} do {
            output:add(inputLayer[i]["train"](inputValues[i], trainValues[i])).
         }
         return output.
      }
      //  Forward pass
      // Evaluate Input layer
      local inputLayerOutput is list().
      from {local i is 0.} until i > inputLayer:length-1 step {set i to i+1.} do {
         inputLayerOutput:add(inputLayer[i]["evaluate"](inputValues[i])).
      }

      // Evaluate hidden layers
      local hiddenLayerOutputs is list().
      from {local i is 0.} until i > hiddenLayers:length-1 step {set i to i+1.} do {
         local layerOutputs is list().
         from {local j is 0.} until j > hiddenLayers[i]:length-1 step {set j to j+1.} do {
            if i = 0 layerOutputs:add(hiddenLayers[i][j]["evaluate"](inputLayerOutput)).
            else layerOutputs:add(hiddenLayers[i][j]["evaluate"](hiddenLayerOutputs[i-1])).
         }
         hiddenLayerOutputs:add(layerOutputs).
      }

      // Evaluate Output layer
      local outputLayerInputs is list().
      if hiddenLayers:length = 0 set outputLayerOutputs to inputLayerOutput.
      else set outputLayerInputs to hiddenLayerOutputs[hiddenLayerOutputs:length-1].
      local outputLayerOutput is list().
      from {local i is 0.} until i > outputLayer:length-1 step {set i to i+1.} do {
         outputLayerOutput:add(outputLayer[i]["evaluate"](outputLayerInputs)).
      }
      /////////////////////

      // Train output layer and begin back propagating 
      local backPropError is list().
      if hiddenLayers:length = 0 {
         set backPropError to trainDenseLayer(inputLayerOutput, outputLayer, trainValues, meanAbsoluteError@, false).
      } else {
         set backPropError to trainDenseLayer(hiddenLayerOutputs[hiddenLayerOutputs:length-1], outputLayer, trainValues, rootMeanSquaredError@, false).
      }

      // Back propagate through hidden layers
      from {local i is hiddenLayers:length-1.} until i < 0 step {set i to i -1.} do {
         if i = 0 set backPropError to trainDenseLayer(inputLayerOutput, hiddenLayers[i], backPropError, meanAbsoluteError@, true). 
         else  set backPropError to trainDenseLayer(hiddenLayerOutputs[i-1], hiddenLayers[i], backPropError).
      }

      local inputTrainValues is backPropError.
      from {local i is 0.} until i > inputLayer:length-1 step {set i to i +1.} do {
         local current is inputLayer[i]["evaluate"](inputValues[i]).
         set inputTrainValues[i] to current + inputTrainValues[i].
      }

      from {local i is 0.} until i > inputLayer:length-1 step {set i to i +1.} do {
         inputLayer[i]["train"](inputValues[i], inputTrainValues[i]).
      }

      return outputLayerOutput.
   }).

   perceptron:add("evaluate network", {
      declare parameter inputValues.
      declare parameter inputLayer.
      declare parameter hiddenLayers.
      declare parameter outputLayer.

      if outputLayer:length = 0 {
         local output is list().
         from {local i is 0.} until i > inputLayer:length - 1 step {set i to i+1.} do {
            output:add(inputLayer[i]["evaluate"](inputValues[i])).
         }
         return output.
      }

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

   declare function normalizeValue {
      declare parameter topi.
      declare parameter bottomi.
      declare parameter topo.
      declare parameter bottomo.
      declare parameter value.

      local output is min(topo, max(bottomo, ((value - bottomi)*(topo - bottomo))/(topi - bottomi))).
      return output.
   }
   perceptron:add("normalize value", normalizeValue@).

   perceptron:add("dead zone", {
      parameter top.
      parameter bottom.
      parameter value.
      if value > bottom and value < top return (top+bottom)/2.
      else return value.
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
      for n in input["inputLayer"] currentList:add(perceptron["new neuron"](n["inputSize"], n["learningRate"], n["activationFunction"], n["bias"], n["weights"])).
      model:add("inputLayer", currentList).
      
      set currentList to list().
      for l in input["hiddenLayers"] {
         local layer is list().
         for n in l layer:add(perceptron["new neuron"](n["inputSize"], n["learningRate"], n["activationFunction"], n["bias"], n["weights"])).
         currentList:add(layer).
      }
      model:add("hiddenLayers", currentList).

      set currentList to list().
      for n in input["outputLayer"] currentList:add(perceptron["new neuron"](n["inputSize"], n["learningRate"], n["activationFunction"], n["bias"], n["weights"])).
      model:add("outputLayer", currentList).

      return model.
   }).

   perceptron:add("training supervisor", {
      
      // Provides values to train against, and may return control output.
      declare parameter outputSupervisorDelegate.
      // Responsible for managing the training session and reverting when out of defined bounds.
      declare parameter sessionDelegate.

      sessionDelegate().
      return outputSupervisorDelegate().

   }).
   
}

