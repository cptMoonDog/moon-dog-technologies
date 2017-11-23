@lazyglobal off.

runpath("0:/lib/launch/launchControl.ks").
runpath("0:/lib/transfer.ks").
launch_ctl["init"](
      lexicon(
              //Countdown type and length
              "launchTime",          "window", 
              "countDownLength",      30,
              //Window parameters
              "lan",                  51.8, //Kerbin Station
              "inclination",          90, 
              //Launch options
              "azimuthHemisphere",   "all"),
              //Launch Vehicle
              "Katlas",
              TRUE, //activate AG2 (fairing)
              TRUE). //Activate AG1 (antennas, solar panels)

launch_ctl["addLaunchToMissionPlan"]().

MISSION_PLAN:add({
   local atn is ship:partsdubbed("Reflectron KR-7")[0].
   local rtMod is atn:getmodule("ModuleRTAntenna").
   rtMod:doevent("activate").
   rtMod:setfield("target", "Kerbin").
   wait 5.
   maneuver_ctl["add_burn"]("prograde", "terrier", "pe", 845).
   return OP_FINISHED.
}).
MISSION_PLAN:add(maneuver_ctl["burn_monitor"]).
kernel_ctl["start"]().
set ship:control:pilotmainthrottle to 0.
