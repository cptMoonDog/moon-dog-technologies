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
   local inclination is 0.
   range_ctl["init"](10).
   steering_ctl["init"](
      lexicon( //Orbit parameters
         "altitude", 80000, 
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
      60000, 1,
      70000, 0.5,
      80000, 0.15
   )).

   local MISSION_PLAN is list().
   MISSION_PLAN:add(range_ctl["countdown"]).
   MISSION_PLAN:add(staging_ctl["launch"]).
   MISSION_PLAN:add({
      staging_ctl["staging"](true, true).
      return throttle_ctl["throttle_monitor"]().
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
