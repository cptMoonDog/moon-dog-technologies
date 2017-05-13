@lazyglobal off.
global kernel is "startup.ks".
global systemFiles is list(
   "ships/" + ship:name + "/startup.ks",
   "ascent/throttleControl.ks",
   "ascent/steeringControl.ks",
   "ascent/stagingControl.ks",
   "lib/rangeControl.ks",
   "lib/maneuver.ks",
   "lib/general.ks" //Library of general purpose functions 
).
