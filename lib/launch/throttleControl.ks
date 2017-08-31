//James McConnel
//Mon Jun 19 19:36:56 PDT 2017
@LAZYGLOBAL OFF.
{
   /// This library's list of  exported functions.
   if not (defined launch_ctl)
      global launch_ctl is lexicon().
   
   local program is 0.

   /// Local variables
   local tableType is "none".
   local pid is 0.

///Public functions
   declare function init {
      if launch_param["throttleProgramType"] = "tableMET" {
         set tableType to "MET".
         set program to throttleSmoother@.
         launch_ctl:add("throttle_monitor", advanceStep@).
      } else if launch_param["throttleProgramType"] = "tableAPO" {
         set tableType to "APO".
         set program to throttleSmoother@.
         launch_ctl:add("throttle_monitor", advanceStep@).
      } else if launch_param["throttleProgramType"] = "etaApo" {
         set program to vETAapo@.
         set pid to PIDLOOP().
         set pid:setpoint to launch_param["throttleProfile"].
         set pid:minoutput to 0.
         set pid:maxoutput to 1.
         launch_ctl:add("throttle_monitor", genericMonitor@).
      } else if launch_param["throttleProgramType"] = "vOV" {
         set program to vOV@.
         set pid to PIDLOOP().
         set pid:minoutput to 0.
         set pid:maxoutput to 1.
         launch_ctl:add("throttle_monitor", genericMonitor@).
      }
         
      launch_ctl:add("throttleProgram", program).
   }
   launch_ctl:add("init_throttle", init@).
   

   // Takes the value of the input buffer compare with the lookup table, and sets the output buffer.
   local step is 0.
   declare function advanceStep {
      if getTableInput() > launch_param["throttleProfile"][step] {
         if step+2 < launch_param["throttleProfile"]:length { //Another step exists
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
         return launch_param["throttleProfile"][step+1].
      } else {
         if getTableInput() > launch_param["throttleProfile"][launch_param["throttleProfile"]:length-2] {
            return 0. 
         } else {
            local Pct is (getTableInput()-launch_param["throttleProfile"][step-2])/
                          (launch_param["throttleProfile"][step]-launch_param["throttleProfile"][step-2]).
            return Pct*(launch_param["throttleProfile"][step+1] - launch_param["throttleProfile"][step-1])+launch_param["throttleProfile"][step-1].
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
      if ship:apoapsis < launch_param["throttleProfile"][0] return 1.
      else if ship:apoapsis > launch_param["throttleProfile"][1] return 0.
      else {
         return pid:update(time:seconds, eta:apoapsis).
         //local val is (eta:apoapsis/launch_param["throttleProfile"][2])*0.5.
         //if val > 0.9 return 0.
         //else return 1-val.
      }
   }

   declare function vOV {
      if ship:apoapsis < launch_param["throttleProfile"][0] return 1.
      else if ship:apoapsis > launch_param["throttleProfile"][1] return 0.
      else {
         return 1-(ship:velocity:orbit:mag/phys_lib["OVatAlt"](Kerbin, ship:altitude)).
      }
   }
}
