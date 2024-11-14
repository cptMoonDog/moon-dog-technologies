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
      declare parameter w is list().
      declare parameter b is 1.

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
         set z to z + 1*1.
         return z.
      }

      neuron:add("propagate error", {
         declare parameter wi.
         declare parameter delta.
         set weights[wi] to weights[wi] + delta.
      }).

      neuron:add("pass input", {
        declare parameter inputs.
        local sum is 0.
        for i in inputs set sum to sum+i.
        return sum+1.
      }).

      declare function eval {
         declare parameter inputs.
         return activation(summation(weights, inputs)).
      }
      neuron:add("evaluate", eval@).

      neuron:add("print weights", {
         declare parameter row.
         print "Bias: "+bias+"                     " at(0, row).
         print "Weights: "+weights+"                              " at(0, row+1).
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

         local current is eval(inputs).
         local delta is (trainValue - current).
         local sumOfz is summation(weights, inputs).

         local backPropError is list().
         from {local i is 0.} until i > weights:length-1 step {set i to i+1.} do {
            set weights[i] to weights[i]-delta*inputs[i]*learningRate.
            backPropError:add(weights[i]*delta).  // The error back propagates
            // Input needs to be adjusted in the same direction as weights?
            if abs(weights[i]) > 1000000 or 
               abs(weights[i]) < 0.000001 
               set weights[i] to random()*2-1.
         }

         return backPropError.

      }).
      
      return neuron.
   }).
   
   declare function trainDenseLayer {
      declare parameter inputs. // list. Multiple inputs for each node, but the same inputs for each node. 
      declare parameter layer.
      declare parameter trainValues. // list. One output for each node.
      declare parameter learningRate is 0.001.

      local backPropError is list().
      from {local i is 0.} until i > layer:length-1 step {set i to i+1.} do {
         local backP is layer[i]["train"](inputs, trainValues[i]).
         if i > 0 { // Sums the back prop error from all the hidden layer nodes into one back prop list
            from {local j is 0.} until j > backPropError:length-1 step {set j to j+1.} do {
               set backPropError[j] to backPropError[j] + backP[j].
            }
         } else set backPropError to backP.
      }
      return backPropError.
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
         //intermVal:add(inputLayer[i]["pass input"](inputValues[i])).
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

      // Generate output for use.
      local oldOutputs is list().

      // Train output layer and begin back propagating 
      local backProp is list().
      if hiddenLayers:length = 0 {
         for n in outputLayer oldOutputs:add(n["evaluate"](intermVal)).
         set backProp to trainDenseLayer(intermVal, outputLayer, trainValues).
      } else {
         for n in outputLayer oldOutputs:add(n["evaluate"](hiddenLayerIntermVals[hiddenLayerIntermVals:length-1])).
         set backProp to trainDenseLayer(hiddenLayerIntermVals[hiddenLayerIntermVals:length-1], outputLayer, trainValues).
      }

      // Back propagate through hidden layers
      from {local i is hiddenLayers:length-1.} until i < 0 step {set i to i -1.} do {
         if i = 0 set backProp to trainDenseLayer(intermVal, hiddenLayers[i], backProp).
         else {
            set backProp to trainDenseLayer(hiddenLayerIntermVals[i-1], hiddenLayers[i], backProp).
         }
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

   perceptron:add("normalize value", {
      declare parameter topi.
      declare parameter bottomi.
      declare parameter topo.
      declare parameter bottomo.
      declare parameter value.

      local output is min(topo, max(bottomo, ((value - bottomi)*(topo - bottomo))/(topi - bottomi))).
      return output.
   }).

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

   perceptron:add("training supervisor", {
      
      // Provides values to train against, and may return control output.
      declare parameter outputSupervisorDelegate.
      // Responsible for managing the training session and reverting when out of defined bounds.
      declare parameter sessionDelegate.

      sessionDelegate().
      return outputSupervisorDelegate().

   }).
   
}

