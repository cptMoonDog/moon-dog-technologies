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
              "quadruplex",
              TRUE, //Stage fairing
              FALSE). //Activate AG1

launch_ctl["addLaunchToMissionPlan"]().

MISSION_PLAN:add({
   wait 5.
   set target to body("Mun").
   local mnvr is node(transfer_ctl["etaPhaseAngle"]()+time:seconds, 0,0, transfer_ctl["dv"]("Kerbin", 80000, "Mun")+4).
   add(mnvr).
   maneuver_ctl["add_burn"]("node", "doubleThud", "node", mnvr:deltav:mag).
   return OP_FINISHED.
}).
MISSION_PLAN:add(maneuver_ctl["burn_monitor"]).
MISSION_PLAN:add({
   if ship:orbit:hasnextpatch and ship:orbit:nextpatch:body = Mun {
      if kuniverse:timewarp:warp = 0 and kuniverse:timewarp:rate = 1 and Kuniverse:timewarp:issettled() and ship:orbit:nextpatcheta > 180 {
         warpto(ship:orbit:nextpatcheta+time:seconds-180).
      }
      return OP_CONTINUE.
   }
   return OP_FINISHED.
}).
MISSION_PLAN:add({
   if ship:orbit:body = body("Mun") {
      maneuver_ctl["add_burn"]("retrograde", "doubleThud", "pe", "circularize").
   }
   return OP_FINISHED.
}).
MISSION_PLAN:add(maneuver_ctl["burn_monitor"]).

kernel_ctl["start"]().
set ship:control:pilotmainthrottle to 0.
