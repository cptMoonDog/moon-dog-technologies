@lazyglobal off.
run kernel.ks.
runpath("throttleControl.ks").
run steeringControl.ks.
run rangeControl.ks.
run stagingControl.ks.
run maneuver.ks.
{
   throttle_ctl["init"](list(
      20000, 1,
      40000, 0.75,
      50000, 0.5,
      60000, 0.3,
      70000, 0.25,
      80000, 0.1
   )).

   steering_ctl["init"](lexicon(
      "alt", 80000, 
      "inc", 90, 
      "pOverDeg", 4, 
      "pOverV0", 30, 
      "pOverVf", 150
   )).


   local SCHEDULE is list(range_ctl["countdown"]).
   SCHEDULE:add(staging_ctl["launch"]()).
   SCHEDULE:add({
      staging_ctl["staging"]().
      return throttle_ctl["throttle_monitor"]().
   }).
   SCHEDULE:add({
      if ship:altitude > 70000 {
         return guidance_ctl["add_burn"]("ap", "circularize", 345, 17.73419501).
      }
   }).
   SCHEDULE:add(guidance_ctl["burn_monitor"]).

   kernel_add_modal_proc(SCHEDULE).
   //kernel_add_proc("terminal", function_name_here@).
   start_kernel().
}

