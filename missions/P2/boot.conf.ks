@lazyglobal off.
global kernel is "main.ks".
global systemFiles is list(
   "ships/" + ship:name + "/main.ks",
   "lib/ascent/steeringControl.ks",
   "lib/ascent/stagingControl.ks",
   "lib/ascent/throttleControl.ks",
   "lib/guidanceControl.ks",
   "lib/kernel.ks",
   "lib/general.ks"
   ).
