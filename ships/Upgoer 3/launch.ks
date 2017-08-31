@lazyglobal off.
{
   launch_ctl["init"](
      lexicon(
              //Countdown type and length
              "launchTime",          "window", 
              "countDownLength",      60,
              //Windows parameters
              "lan",                  78, 
              "inclination",          6, 
              //Launch options
              "azimuthHemisphere",   "north",
              //Fudge factor
              "timeOfFlight",         45, 
              //Gravity turn parameters
              "pOverDeg",             5, 
              "pOverV0",              30, 
              "pOverVf",              100,
              //Throttle program parameters
              "throttleProgramType", "tableAPO", 
              "throttleProfile", list(
                                      30000, 1,
                                      50000, 0.5,
                                      70000, 0.25,
                                      80000, 0.1
                                     )
             )
   ).
   
// launch_ctl["init_throttle"]( "tableMET", list(
//     60, 1,
//     120, 0.5,
//     240, 0.25,
//     320, 0.1
     
  //launch_ctl["init_throttle"]( "etaApo", list(
     //20000, 80000, 45

   //)).

   lock throttle to launch_ctl["throttleProgram"]().
   lock steering to launch_ctl["steeringProgram"]().

   MISSION_PLAN:add(launch_ctl["countdown"]).
   MISSION_PLAN:add(launch_ctl["launch"]).
   MISSION_PLAN:add({
     launch_ctl["staging"]().
     return launch_ctl["throttle_monitor"]().
   }).
   MISSION_PLAN:add({
      if ship:altitude > 70000 {
         maneuver_ctl["add_burn"]("ap", "circularize", 350, 72.83687236).
         return OP_FINISHED.
      } else return OP_CONTINUE.
   }).
   MISSION_PLAN:add(maneuver_ctl["burn_monitor"]).
   kernel_ctl["start"]().
   set ship:control:pilotmainthrottle to 0.
}

