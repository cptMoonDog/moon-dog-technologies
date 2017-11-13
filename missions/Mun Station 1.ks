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
              "katlas", "terrier").

launch_ctl["addLaunchToMissionPlan"]().

MISSION_PLAN:add({
   wait 5.
   local dv is visViva_velocity(body("Kerbin"), 80000, smaOfTransferOrbit(body("Kerbin"), 80000, 775000)-visViva_velocity(body("Kerbin"), 80000, 80000+Kerbin:radius).
   maneuver_ctl["add_burn"]("prograde", "terrier", "pe", dv).
   return OP_FINISHED.
}).
MISSION_PLAN:add(maneuver_ctl["burn_monitor"]).

kernel_ctl["start"]().
set ship:control:pilotmainthrottle to 0.
