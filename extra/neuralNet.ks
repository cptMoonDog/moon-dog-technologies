
local weights is list(
   list(list(1, 1, 1, 1), list(1, 1, 1, 1), list(1, 1, 1, 1)), // Layer 1
   list(list(1, 1, 1, 1), list(1, 1, 1, 1), list(1, 1, 1, 1)), // Layer 2
   list(list(1, 1, 1, 1), list(1, 1, 1, 1), list(1, 1, 1, 1)), // Layer 3
   list(list(1, 1, 1, 1)) // Layer 4 (Output)
).

local networkOutputs is list().

declare function activation {
   declare parameter input.
   return input/sqrt(1+input^2).
}

declare function summation {
   declare parameter weights.
   declare parameter inputs.

   local z is 0.
   from {local i is 0.} until i > inputs:length-1 step {set i to i+1.} do {
     set z to z + weights[i+1]*inputs[i]. 
   }
   set z to z + weights[0].
   return z.
}
      
declare function evaluateNetwork {
   declare parameter networkWeights.
   declare parameter input.

   local currentInput is input.
   for layer in networkWeights {
      set currentInput to evaluateLayer(currentInput, layer).
      networkOutputs:add(currentInput).
   }
   return currentInput. //Output of the last layer of the network
}

declare function evaluateLayer {
   declare parameter input.
   declare parameter layer.
   local output is list().
   for n in layer {
      output:add(summation(n, input)).
   }
   return output.
}

declare function updateWeights {
   declare parameter expectedOutput.
   declare parameter actualOutput.
   declare parameter netNode.
   declare parameter inputs.

   local learningRate is 0.1.
   local loss is abs(expectedOutput - actualOutput).
   local updatedWeights is list().
   updatedWeights:add(netNode[0]-learningRate*loss*2).

   from {local i is 0.} until i > inputs:length-1 step {set i to i+1.} do {
      updatedWeights:add(netNode[i+1]-2*loss*inputs[i]*learningRate).
   }
   return updatedWeights.
}

local networkInputs is list(5, 5, 5).
local finalOutput is evaluateNetwork(weights, networkInputs).

local desiredOutput is list(0.9).

local outputsReverse is networkOutputs:reverseIterator.
local weightsLayerReverseIndex is weights:length-1.
local weightsCurrentNodeIndex is 0.

until not outputsReverse:next {

   local layerOutput is outputsReverse:value.
   outputsReverse:next.
   local layerInput is list().
   if outputsReverse:atend set layerInput to networkInputs.
   else {
      outputsReverse:next.
      set layerInput to outputsReverse:value.
   }

   from {local i is 0.} until i > layerOutput:length-1 step {set i to i+1.} do {
      local u is updateWeights(desiredOutput[i], layerOutput[i], weights[weightsLayerReverseIndex][weightsCurrentNodeIndex], layerInput).
      set weights[weightsLayerReverseIndex][weightsCurrentNodeIndex] to u.
      print weights[weightsLayerReverseIndex][weightsCurrentNodeIndex] at(0, 10+i*outputsReverse:index).
      set desiredOutput to weights[weightsLayerReverseIndex][weightsCurrentNodeIndex].
   }

}
