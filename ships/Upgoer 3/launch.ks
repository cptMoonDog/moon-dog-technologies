@lazyglobal off.
{
   launch_ctl["init"](
      lexicon(
              //Countdown type and length
              "launchTime",          "window", 
              "countDownLength",      30,
              //Window parameters
              "lan",                  78, 
              "inclination",          6, 
              //Launch options
              "azimuthHemisphere",   "north",
              //Fudge factor
              "timeOfFlight",         100, 
              //Gravity turn parameters
              "pOverDeg",             5, 
              "pOverV0",              30, 
              "pOverVf",              130,
              //Throttle program parameters
              //Throttle program for Upgoer 3 on laptop
//              "throttleProgramType", "tableAPO", 
//              "throttleProfile", list(
//                                      15000, 1,
//                                      30000, 0.5,
//                                      50000, 0.3,
//                                      55000, 0.75,
//                                      80000, 0.5

              //Throttle program for Upgoer 3 on desktop
              "throttleProgramType", "tableAPO", 
              "throttleProfile", list(
                                      15000, 1,
                                      80000, 0.1

//              "throttleProgramType", "tableMET", 
//              "throttleProfile", list(
//                                      60, 1,
//                                      120, 0.5,
//                                      240, 0.25,
//                                      320, 0.1
//
//              "throttleProgramType", "etaApo", 
//              "throttleProfile", list( 
//                                      20000, //Apo to Activate function, max prior
//                                      80000, //Apo to Deactivate function 
//                                      45     //Setpoint

                                    )
             )
   ).

   //////////////////Begin mission planning
   MISSION_PLAN:add(launch_ctl["countdown"]).
   MISSION_PLAN:add(launch_ctl["launch"]).
   MISSION_PLAN:add({
     //Calls staging check, and throttle defines end of this mode.
     launch_ctl["staging"]().
     return launch_ctl["throttle_monitor"]().
   }).
   MISSION_PLAN:add({
      maneuver_ctl["add_burn"](launch_ctl["steeringProgram"], 350, 72.83687236, "ap", "circularize").
      return OP_FINISHED.
   }).
   MISSION_PLAN:add(maneuver_ctl["burn_monitor"]).
   MISSION_PLAN:add({
      wait 5.
      set target to body("Minmus").
      local dv is visViva_velocity(body("Kerbin"), 80000, smaOfTransferOrbit(body("Kerbin"), 80000, body("Minmus"):altitude))-ship:orbit:velocity:mag.
      add(node(transfer_ctl["etaTarget"]()+time:seconds, 0,0,dv)).
      maneuver_ctl["add_burn"]("node", 350, 72.83687236, "node").
      return OP_FINISHED.
   }).
   MISSION_PLAN:add(maneuver_ctl["burn_monitor"]).
   MISSION_PLAN:add({
      if ship:orbit:hasnextpatch {
         warpto(ship:orbit:nextpatcheta-180).
      }
      return OP_FINISHED.
   }).
   MISSION_PLAN:add({
      maneuver_ctl["add_burn"]("retrograde", 350, 72.83687236, "pe", "circularize").
      return OP_FINISHED.
   }).
   MISSION_PLAN:add(maneuver_ctl["burn_monitor"]).

   kernel_ctl["start"]().
   set ship:control:pilotmainthrottle to 0.
}

