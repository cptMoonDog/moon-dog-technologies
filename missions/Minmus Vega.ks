@lazyglobal off.

runpath("0:/lib/launch/launchControl.ks").
runpath("0:/lib/transfer.ks").
launch_ctl["init"](
      lexicon(
              //Countdown type and length
              "launchTime",          "window", 
              "countDownLength",      30,
              //Window parameters
              "lan",                  78, 
              "inclination",          6, 
              //Launch options
              "azimuthHemisphere",   "north"),
              //Launch Vehicle
              "Vega 1", "small dog").

   MISSION_PLAN:add({
      wait 5.
      set target to body("Minmus").
      local dv is 4+visViva_velocity(body("Kerbin"), 80000, smaOfTransferOrbit(body("Kerbin"), 80000, body("Minmus"):altitude))-visViva_velocity(body("Kerbin"), 80000, 80000+Kerbin:radius).
      add(node(transfer_ctl["etaTarget"]()+time:seconds, 0,0,dv)).
      maneuver_ctl["add_burn"]("node", 350, 72.83687236, "node").
      return OP_FINISHED.
   }).
   MISSION_PLAN:add(maneuver_ctl["burn_monitor"]).
   MISSION_PLAN:add({
      stage.
      return OP_FINISHED.
   }).
   MISSION_PLAN:add({
      if ship:orbit:hasnextpatch and ship:orbit:nextpatch:body = Minmus {
         if kuniverse:timewarp:warp = 0 and kuniverse:timewarp:rate = 1 and Kuniverse:timewarp:issettled() and ship:orbit:nextpatcheta > 180 {
            warpto(ship:orbit:nextpatcheta+time:seconds-180).
         }
         return OP_CONTINUE.
      }
      return OP_FINISHED.
   }).
   MISSION_PLAN:add({
      if ship:orbit:body = body("Minmus") {
         maneuver_ctl["add_burn"]("retrograde", 345, 17.73419501, "pe", "circularize").
      }
      return OP_FINISHED.
   }).
   MISSION_PLAN:add(maneuver_ctl["burn_monitor"]).

kernel_ctl["start"]().
set ship:control:pilotmainthrottle to 0.
