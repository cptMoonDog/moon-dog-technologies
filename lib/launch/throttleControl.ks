//James McConnel
//Mon Jun 19 19:36:56 PDT 2017
@LAZYGLOBAL OFF.
{
//   runoncepath("general.ks").
   /// This library's list of  exported functions.
   if not (defined ascent_ctl)
      global ascent_ctl is lexicon().
   
   local program is 0.
   local profile is list(). //Expecting list. Believe it or not, list seems better in this application.

   /// Local variables
   local tableType is "none".
   local pid is 0.

///Public functions
   declare function init {
      parameter c.
      parameter p.
      set profile to p.
      if c = "tableMET" {
         set tableType to "MET".
         set program to throttleSmoother@.
         ascent_ctl:add("throttle_monitor", advanceStep@).
      } else if c = "tableAPO" {
         set tableType to "APO".
         set program to throttleSmoother@.
         ascent_ctl:add("throttle_monitor", advanceStep@).
      } else if c = "etaApo" {
         set program to vETAapo@.
         set pid to PIDLOOP().
         set pid:setpoint to profile[2].
         set pid:minoutput to 0.
         set pid:maxoutput to 1.
         ascent_ctl:add("throttle_monitor", genericMonitor@).
      } else if c = "vOV" {
         set program to vOV@.
         set pid to PIDLOOP().
         set pid:minoutput to 0.
         set pid:maxoutput to 1.
         ascent_ctl:add("throttle_monitor", genericMonitor@).
      }
         
      ascent_ctl:add("throttleProgram", program).
   }
   ascent_ctl:add("init_throttle", init@).
   

   // Takes the value of the input buffer compare with the lookup table, and sets the output buffer.
   local step is 0.
   declare function advanceStep {
      if getTableInput() > profile[step] {
         if step+2 < profile:length { //Another step exists
            set step to step+2.
         } else {
            //This prevents the program from shutting down if drag could still have an influence.
            if (not (ship:orbit:body:atm:exists)) or ship:altitude > ship:orbit:body:atm:height  {
               return OP_FINISHED.
            }
         }
      } 
      return OP_CONTINUE.
   }
   
   declare function genericMonitor {
      //This prevents the program from shutting down if drag could still have an influence.
      if (not (ship:orbit:body:atm:exists)) or ship:altitude > ship:orbit:body:atm:height  {
         return OP_FINISHED.
      }
      return OP_CONTINUE.
   }
   
///Private functions
   // Lookup table throttle control 
   declare function throttleSmoother {
      if step = 0 {
         return profile[step+1].
      } else {
         if getTableInput() > profile[profile:length-2] {
            return 0. 
         } else {
            local Pct is (getTableInput()-profile[step-2])/
                          (profile[step]-profile[step-2]).
            return Pct*(profile[step+1] - profile[step-1])+profile[step-1].
         }
      }
   }
   //Utility function for table lookup system.
   declare function getTableInput {
      if tableType = "MET"
         return MISSIONTIME.
      else if tableType = "APO"
         return ship:apoapsis.
      else return 0.
   }

 ///Non-table based throttling methods.
   //Expects the following profile:
   //Apoapsis value beyond which the function will apply.  Full throttle prior.
   //Apoapsis value at which to shutdown.  Presumably the orbital altitude.
   declare function vETAapo {
      if ship:apoapsis < profile[0] return 1.
      else if ship:apoapsis > profile[1] return 0.
      else {
         return pid:update(time:seconds, eta:apoapsis).
         //local val is (eta:apoapsis/profile[2])*0.5.
         //if val > 0.9 return 0.
         //else return 1-val.
      }
   }

   declare function vOV {
      if ship:apoapsis < profile[0] return 1.
      else if ship:apoapsis > profile[1] return 0.
      else {
         return 1-(ship:velocity:orbit:mag/phys_lib["OVatAlt"](Kerbin, ship:altitude)).
      }
   }
}
