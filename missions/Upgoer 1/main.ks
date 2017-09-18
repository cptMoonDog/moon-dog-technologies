@lazyglobal off.
runpath("throttleControl.ks").
runpath("steeringControl.ks").
runpath("rangeControl.ks").
runpath("stagingControl.ks").
runpath("guidanceControl.ks").
runpath("kernel.ks").
{
   local hemisphere is "north".
   local inclination is 0.
   range_ctl["init"](10).
   //lexicon(
   //      "lan", 0,
   //      "inclination", inclination,
   //      "tof", 0,
   //      "hemisphere", hemisphere
   //   )
   //).
   ascent_ctl["init_steering"](
      lexicon( //Orbit parameters
         "altitude", 80000, 
         "inclination", inclination 
      ), 
      lexicon( //Ascent Parameters
         "hemisphere", hemisphere,
         "pOverDeg", 4.5, 
         "pOverV0", 30, 
         "pOverVf", 145
      )
   ).
   lock steering to ascent_ctl["steeringProgram"]().
  
   ascent_ctl["init_throttle"](list(
      10000, 1,
      80000, 0.15
   )).
   lock throttle to ascent_ctl["throttleProgram"]().
   set ship:control:pilotmainthrottle to 0.
   list.

   //INTERRUPTS:add().


   local MISSION_PLAN is list().
   MISSION_PLAN:add(range_ctl["countdown"]).
   MISSION_PLAN:add(ascent_ctl["launch"]).
   MISSION_PLAN:add({
     ascent_ctl["staging"]().
     return ascent_ctl["throttle_monitor"]().
   }).
   MISSION_PLAN:add({
      if ship:altitude > 70000 {
         guidance_ctl["add_burn"]("ap", "circularize", 345, 17.73419501).
         return OP_FINISHED.
      } else return OP_CONTINUE.
   }).
   MISSION_PLAN:add(guidance_ctl["burn_monitor"]).
   kernel_ctl["start"](MISSION_PLAN).
}

