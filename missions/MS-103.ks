@lazyglobal off.

runpath("0:/lib/launch/launchControl.ks").
runpath("0:/lib/transfer.ks").
launch_ctl["init"](
      lexicon(
              //Countdown type and length
              "launchTime",          "now", 
              "countDownLength",      30,
              //Window parameters
              //"lan",                  0, 
              "inclination",          0, 
              //Launch options
              "azimuthHemisphere",   "north"),
              //Launch Vehicle
              "thor",
              TRUE, //Stage fairing
              FALSE). //Activate AG1

launch_ctl["addLaunchToMissionPlan"]().

runpath("0:/lib/prefab.ks").
prefab_LKOToMun("skipper").
prefab_warpToSOI("Mun").
prefab_poweredCapture("Mun", "skipper").

kernel_ctl["start"]().
set ship:control:pilotmainthrottle to 0.
