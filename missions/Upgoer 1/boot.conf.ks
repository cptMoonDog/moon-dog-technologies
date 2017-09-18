@lazyglobal off.
global kernel is "main.ks".
global systemFiles is list(
   "ships/" + ship:name + "/main.ks",
   "lib/ascent/throttleControl.ks",
   "lib/ascent/steeringControl.ks",
   "lib/ascent/stagingControl.ks",
   "lib/rangeControl.ks",
   "lib/guidanceControl.ks",
   "lib/general.ks", //Library of general purpose functions 
   "lib/core/kernel.ks"
).
