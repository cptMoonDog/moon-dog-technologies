@lazyglobal off.

runpath("0:/lib/launch/launchControl.ks").
runpath("0:/lib/transfer.ks").
launch_ctl["init"](
      lexicon(
              //Countdown type and length
              "launchTime",          "now", 
              "countDownLength",      30,
              //Window parameters
              //"lan",                  190.97659, //Kerbin Station
              "inclination",          90, 
              //Launch options
              "azimuthHemisphere",   "north"),
              //Launch Vehicle
              "Katlas", TRUE, TRUE).

launch_ctl["addLaunchToMissionPlan"]().

kernel_ctl["start"]().
set ship:control:pilotmainthrottle to 0.
