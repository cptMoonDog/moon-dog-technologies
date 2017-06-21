//James McConnel
//Mon Jun 19 19:36:56 PDT 2017
@LAZYGLOBAL OFF.
{
   /// This library's list of  exported functions.
   if not defined ascent_ctl 
      global ascent_ctl is lexicon().
   
   /// Parameters
   parameter profile. //Expecting list. Believe it or not, list seems better in this application.

   /// Local variables
   local step is 0.

///Public functions
   
   //Stub that calls the lookup table monitor and then the throttle control.
   declare function stub {
      parameter pvar.
      throttleSmoother(pvar).
      return advanceStep(pvar).
   }
   ascent_ctl:add("throttle_monitor", stub@).

///Private functions

   // Takes the value of the input buffer compare with the lookup table, and sets the output buffer.
   declare function advanceStep {
      parameter pvar.

      if pvar > profile[step] {
         if step+2 < profile:length { //Another step exists
            set step to step+2.
         } else {
            //This prevents the program from shutting down if drag could still have an influence.
            if not ship:orbit:body:atm:exists or ship:altitude > ship:orbit:body:atm:height  {
               set ship:control:pilotmainthrottle to 0.
               return OP_FINISHED.
            }
         }
      } else if pvar < profile[step-2] set step to step-2. //pvar has regressed past the previous value.
      return OP_CONTINUE.
   }
   
   // Primary throttle control function 
   declare function throttleSmoother {
      parameter pvar.
      
      if step = 0 return profile[step+1].
      else if step >= profile:length return 0.
      else {
         if pvar > profile[profile:length-2] return 0. 
         else {
            local altPct is (pvar-profile[step-2])/
                          (profile[step]-profile[step-2]).
            local thrott is altPct*(profile[step+1] - profile[step-1])+profile[step-1].
            set throttle to thrott.
         }
      }
   }
}
