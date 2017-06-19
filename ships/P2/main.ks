@lazyglobal off.
//Remote 
runpath("0:/lib/rangeControl.ks").
//Local
runpath("throttleControl.ks").
runpath("steeringControl.ks").
runpath("stagingControl.ks").
runpath("guidanceControl.ks").
runpath("kernel.ks").
{
   local hemisphere is "north".
   local inclination is 22.3.
   range_ctl["init"](lexicon("lan", 129.5, "inclination", inclination, "tof", 130, "hemisphere", hemisphere)).
   steering_ctl["init"](
      lexicon( //Orbit parameters
         "altitude", 19451874, 
         "inclination", inclination 
      ), 
      lexicon( //Ascent Parameters
         "hemisphere", hemisphere,
         "pOverDeg", 5, 
         "pOverV0", 20, 
         "pOverVf", 150
      )
   ).
  
   throttle_ctl["init"](list(
      10000, 1,
      80000, 1,
      10000000, 0.5,
      19451874, 0.01
   )).

   local MISSION_PLAN is list().
   MISSION_PLAN:add(range_ctl["countdown"]).
   MISSION_PLAN:add(staging_ctl["launch"]).
   MISSION_PLAN:add({
      staging_ctl["staging"](true, true).
      return throttle_ctl["throttle_monitor"]().
   }).
   MISSION_PLAN:add({
      if ship:altitude > 19000000 {
         guidance_ctl["add_burn"]("ap", "circularize", 345, 17.73419501).
         return OP_FINISHED.
      } else return OP_CONTINUE.
   }).
   MISSION_PLAN:add(guidance_ctl["burn_monitor"]).
   kernel_ctl["start"](MISSION_PLAN).
} 
