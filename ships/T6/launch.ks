@lazyglobal off.
runpath("0:/lib/rangeControl.ks").

copypath("0:/lib/core/kernel.ks", "").
runpath("kernel.ks").

copypath("0:/lib/ascent/stagingControl.ks", "").
runpath("stagingControl.ks").

copypath("0:/lib/ascent/steeringControl.ks", "").
runpath("steeringControl.ks").

copypath("0:/lib/general.ks", "").
runpath("general.ks").

copypath("0:/lib/ascent/throttleControl.ks", "").
runpath("throttleControl.ks").

copypath("0:/lib/guidanceControl.ks", "").
runpath("guidanceControl.ks").

{
   range_ctl["init"](10).
   ascent_ctl["init_steering"](
      lexicon( //Orbit parameters
         "altitude", 80000, 
         "inclination", 0 
      ), 
      lexicon( //Ascent Parameters
         "hemisphere", "north",
         "pOverDeg", 7, 
         "pOverV0", 30, 
         "pOverVf", 100
      )).
   ascent_ctl["init_throttle"]( list(
      20000, 1,
      60000, 0.5,
      75000, 1,
      80000, 0.3
   )).
   set ship:control:pilotmainthrottle to 0.

   lock throttle to ascent_ctl["throttleProgram"]().
   lock steering to ascent_ctl["steeringProgram"]().

   local MISSION_PLAN is list().
   MISSION_PLAN:add(range_ctl["countdown"]).
   MISSION_PLAN:add(ascent_ctl["launch"]).
   MISSION_PLAN:add({
     ascent_ctl["staging"]().
     return ascent_ctl["throttle_monitor"]().
   }).
   MISSION_PLAN:add({
      if ship:altitude > 70000 {
         guidance_ctl["add_burn"]("ap", "circularize", 310, 78.9577133).
         return OP_FINISHED.
      } else return OP_CONTINUE.
   }).
   MISSION_PLAN:add(guidance_ctl["burn_monitor"]).
   kernel_ctl["start"](MISSION_PLAN).
}

