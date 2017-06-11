@lazyglobal off.
runpath("throttleControl.ks").
runpath("steeringControl.ks").
runpath("rangeControl.ks").
runpath("stagingControl.ks").
runpath("maneuver.ks").
runpath("kernel.ks").
{
   local hemisphere is "south".
   local inclination is 45.33087.
   range_ctl["init"](lexicon(
         "lan", 40,
         "inclination", inclination,
         "tof", 140,
         "hemisphere", hemisphere
      )
   ).
   steering_ctl["init"](
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
  
   throttle_ctl["init"](list(
      10000, 1,
      20000, 0.75,
      40000, 0.6,
      50000, 0.5,
      60000, 0.25,
      70000, 0.2,
      80000, 0.15
   )).

   //INTERRUPTS:add().


   local MISSION_PLAN is list().
   MISSION_PLAN:add(range_ctl["countdown"]).
   MISSION_PLAN:add(staging_ctl["launch"]).
   MISSION_PLAN:add({
      staging_ctl["staging"]().
      return throttle_ctl["throttle_monitor"]().
   }).
   MISSION_PLAN:add({
      if ship:altitude > 70000 {
         guidance_ctl["add_burn"]("ap", "circularize", 345, 17.73419501).
         return OP_FINISHED.
      } else return OP_CONTINUE.
   }).
   MISSION_PLAN:add(guidance_ctl["burn_monitor"]).
   MISSION_PLAN:add(guidance_ctl["findtransfer"]).
   kernel_ctl["start"](MISSION_PLAN).
}

