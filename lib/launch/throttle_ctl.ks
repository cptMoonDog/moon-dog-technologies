//James McConnel
//Mon Jun 19 19:36:56 PDT 2017
@LAZYGLOBAL OFF.
{
   /// This library's list of  exported functions.
   if not (defined launch_ctl)
      global launch_ctl is lexicon().

   /// Local variables
   local pid is 0.
   local throttFunction is 0.
   local lastThrottVal is 1.

   declare function init {
      if launch_param["throttleProgramType"] = "table" {
         lock throttle to getThrottleSetting_table().
         launch_ctl:add("throttle_monitor", throttleMonitor_table@).
      } else {
         if launch_param["throttleProgramType"] = "setpoint" {
            set throttFunction to thrott_function_setpoint@.
            set pid to PIDLOOP().
            set pid:setpoint to launch_param["throttleProfile"][2].
            set pid:minoutput to 0.
            set pid:maxoutput to 1.
         } else if launch_param["throttleProgramType"] = "function" {
            if not (defined throttle_functions)
               runpath("0:/config/launch/throttle-functions.ks").
           
            set throttFunction to throttle_functions[launch_param["throttleFunction"]].
         }
         lock throttle to getThrottleSetting_function().
         launch_ctl:add("throttle_monitor", throttleMonitor_function@).
      }
   }
   launch_ctl:add("init_throttle", init@).
   
   /////// Reference Value getters
   //Utility function for table lookup system. Returns the Reference Value.
   declare function getReferenceValue_table {
      if launch_param["throttleReferenceVar"] = "MET"
         return MISSIONTIME.
      else if launch_param["throttleReferenceVar"] = "APO"
         return ship:apoapsis.
      else return 0.
   }
   //Utility function for the setpoint throttling system. Returns the Reference Value.
   local currentThrust is 0.
   local lastRefCheck is time:seconds.
   declare function getReferenceValue_setpoint {
     if launch_param["throttleReferenceVar"] = "etaAPO"
        return eta:apoapsis.
      else return 0.
   }

   /////// Monitors (A function that reports to the kernel during the zero-lift portion of the launch sequence.)
   // Monitors the value of the Reference Variable and advances through the table.
   // If a table based profile is selected by the lv, this will be exported as launch_ctl["throttleMonitor"]
   local step is 0.
   declare function throttleMonitor_table {
      if getReferenceValue_table() > launch_param["throttleProfile"][step] {
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
   // If shutdown condition reached, cut throttle, but stay alive until above atmosphere.
   // If a function or setpoint based profile is selected by the lv, this will be exported as launch_ctl["throttleMonitor"]
   declare function throttleMonitor_function {
      //This prevents the program from shutting down if drag could still have an influence.
      if ship:apoapsis >= launch_param["throttleProfile"][1] and ((not (ship:orbit:body:atm:exists)) or ship:altitude > ship:orbit:body:atm:height)  {
         lock throttle to 0.
         return OP_FINISHED.
      }
      return OP_CONTINUE.
   }

   //////// Throttle setters (Functions that throttle can be locked to.)
   local kickWithin is 1.5.
   //Returns the throttle setting
   // If a table based profile is selected by the lv, the throttle will be locked to this function.
   declare function getThrottleSetting_table {
      if step = 0 {
         return launch_param["throttleProfile"][step+1].
      } else {
         if getReferenceValue_table() > launch_param["throttleProfile"][launch_param["throttleProfile"]:length-2] {
            return 0. 
         } else {
            if vang(up:forevector, ship:facing:forevector) > 90-kickWithin and vang(up:forevector, ship:facing:forevector) < 90+kickWithin {
               //What am I doing here?  Okay, if ship:prograde is within 1 deg (either side) of horizontal...
               //function will return 0@89 deg, rise to 1@90 deg and fall to 0@91 deg. I.e. max thottle at horizontal prograde.
               //Adds the final kick to orbital altitude, if not there already. 
               //Max function ensures this will not cause throttling down, if already throttled up.
               return max(-1*abs(vang(up:forevector, ship:prograde:forevector)-90)+kickWithin, 
                  launch_param["throttleProfile"][step-1] + smoothInterval(launch_param["throttleProfile"][step], 
                                                                           launch_param["throttleProfile"][step-2], 
                                                                           getReferenceValue_table(), 
                                                                           (launch_param["throttleProfile"][step+1] - launch_param["throttleProfile"][step-1]))).
            } else {
               return launch_param["throttleProfile"][step-1] + smoothInterval(launch_param["throttleProfile"][step], 
                                                                              launch_param["throttleProfile"][step-2], 
                                                                              getReferenceValue_table(), 
                                                                              (launch_param["throttleProfile"][step+1] - launch_param["throttleProfile"][step-1])).
            }
         }
      }
   }
   // If a function or setpoint based profile is selected by the lv, the throttle will be locked to this function.
   //Expects the following profile:
   //Apoapsis value beyond which the function will apply.  Full throttle prior.
   //Apoapsis value at which to shutdown.  Presumably the orbital altitude.
   declare function getThrottleSetting_function {
      if ship:apoapsis < launch_param["throttleProfile"][0] or eta:periapsis < eta:apoapsis return 1.
      else if ship:apoapsis > launch_param["throttleProfile"][1] return 0.
      else if vang(up:forevector, ship:facing:forevector) > 90-kickWithin and vang(up:forevector, ship:facing:forevector) < 90+kickWithin {
         //What am I doing here?  Okay, if ship:prograde is within 1 deg (either side) of horizontal...
         //function will return 0@89 deg, rise to 1@90 deg and fall to 0@91 deg. I.e. max thottle at horizontal prograde.
         //Adds the final kick to orbital altitude, if not there already. 
         //Max function ensures this will not cause throttling down, if already throttled up.
         if launch_param["throttleProfile"]:length = 3 // If a setpoint, or parameter for the function is provided, pass it.
            return max(throttFunction(launch_param["throttleProfile"][2]), -1*abs(vang(up:forevector, ship:prograde:forevector)-90)+kickWithin).
         else
            return max(throttFunction(), -1*abs(vang(up:forevector, ship:prograde:forevector)-90)+kickWithin).
      } else {
         if launch_param["throttleProfile"]:length = 3
            return throttFunction(launch_param["throttleProfile"][2]).
         else
            return throttFunction().
      }
   }

   ///////// Misc
   //Utility to make getThrottleSetting_table easier
   declare function smoothInterval {
      parameter top.
      parameter bottom.
      parameter current.
      parameter outputRange.

      return ((current-bottom)/(top-bottom))*outputRange.
   }

   //Returns the throttle setting
   // If a setpoint based profile is selected by the lv, this will be the throttFunction.
   declare function thrott_function_setpoint {
      parameter throwaway is eta:apoapsis.
      return pid:update(time:seconds, getReferenceValue_setpoint()).
   }
   
     

}
