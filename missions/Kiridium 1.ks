@lazyglobal off.

runpath("0:/lib/launch/launchControl.ks").
runpath("0:/lib/transfer.ks").
launch_ctl["init"](
      lexicon(
              //Countdown type and length
              "launchTime",          "window", 
              "countDownLength",      30,
              //Window parameters
              "lan",                  190.97659, //Kerbin Station
              "inclination",          89.67241, 
              //Launch options
              "azimuthHemisphere",   "north"),
              //Launch Vehicle
              "Laika", "terrier").

launch_ctl["addLaunchToMissionPlan"]().

kernel_ctl["start"]().
set ship:control:pilotmainthrottle to 0.
