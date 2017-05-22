//James McConnel
//3/24/2017
@LAZYGLOBAL OFF.
{
   global throttle_ctl is lexicon().
   local profile is list( //Believe it or not, list seems better in this application.
      20000, 1,
      40000, 0.75,
      50000, 0.5,
      60000, 0.3,
      70000, 0.25,
      80000, 0.1
   ).
   declare function init {
      parameter p.
      set profile to p.
      lock throttle to throttleSmoother(step).
   }
   throttle_ctl:add("init", init@).

   local step is 0.

   declare function advanceStep {
      if ship:apoapsis > profile[step] {
         if step+2 < profile:length {
            set step to step+2.
         } else {
            if ship:altitude < 70000 {
               if ship:apoapsis < profile[step] set step to step-2.
            } else {
               set ship:control:pilotmainthrottle to 0.
               return OP_FINISHED.
            }
         }
      } 
      return OP_CONTINUE.
   }
   throttle_ctl:add("throttle_monitor", advanceStep@).

   declare function throttleSmoother {
      declare parameter step.
      if step = 0 return profile[step+1].
      else if step >= profile:length return 0.
      else {
         if ship:apoapsis > profile[profile:length-2] return 0. 
         else {
            local altPct is (ship:apoapsis-profile[step-2])/
                          (profile[step]-profile[step-2]).
            local thrott is altPct*(profile[step+1] - profile[step-1])+profile[step-1].
            return thrott.
         }
      }
   }
}
