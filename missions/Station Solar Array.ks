@lazyglobal off.

runpath("0:/lib/launch/launchControl.ks").
launch_ctl["init"](
      lexicon(
              //Countdown type and length
              "launchTime",          "window", 
              "countDownLength",      30,
              //Window parameters
              "lan",                  190.97659, //Kerbin Station
              "inclination",          89.67241, 
              //Launch options
              "azimuthHemisphere",   "all"),

              //Launch Vehicle
              "Laika",
              TRUE, //Stage fairing
              TRUE). //Activate AG1

launch_ctl["addLaunchToMissionPlan"]().

kernel_ctl["start"]().
set ship:control:pilotmainthrottle to 0.
