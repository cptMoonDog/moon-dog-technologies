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

///Public functions
   declare function init {
      if launch_param["throttleProgramType"] = "table" {
         lock throttle to throttleSmoother().
         launch_ctl:add("throttle_monitor", advanceStep@).
      } else {
         if launch_param["throttleProgramType"] = "setpoint" {
            set throttFunction to thrott_function_setpoint@.
            set pid to PIDLOOP().
            set pid:setpoint to launch_param["throttleProfile"][2].
            set pid:minoutput to 0.
            set pid:maxoutput to 1.
            launch_ctl:add("throttle_monitor", genericMonitor@).
         } else if launch_param["throttleProgramType"] = "function" {
            if not (defined throttle_functions)
               runpath("0:/config/throttle-functions.ks").
           
            set throttFunction to throttle_functions[launch_param["throttleFunction"]].
         }
         lock throttle to functionThrottler().
      }
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
   
///Private functions
   // Lookup table throttle control 
   declare function throttleSmoother {
      if step = 0 {
         return launch_param["throttleProfile"][step+1].
      } else {
         if getTableInput() > launch_param["throttleProfile"][launch_param["throttleProfile"]:length-2] {
            return 0. 
         } else {
            return launch_param["throttleProfile"][step-1] + smoothInterval(launch_param["throttleProfile"][step], 
                                                                            launch_param["throttleProfile"][step-2], 
                                                                            getTableInput(), 
                                                                            (launch_param["throttleProfile"][step+1] - launch_param["throttleProfile"][step-1])).
         }
      }
   }

   declare function smoothInterval {
      parameter top.
      parameter bottom.
      parameter current.
      parameter outputRange.

      return ((current-bottom)/(top-bottom))*outputRange.
   }

   //Utility function for table lookup system.
   declare function getTableInput {
      if launch_param["throttleReferenceVar"] = "MET"
         return MISSIONTIME.
      else if launch_param["throttleReferenceVar"] = "APO"
         return ship:apoapsis.
      else return 0.
   }

   declare function getSetpointReferenceVar {
     if launch_param["throttleReferenceVar"] ="APO"
       return eta:apoapsis.
     else return 0.
   }
     
 ///Non-table based throttling methods.
   declare function thrott_function_setpoint {
      return pid:update(time:seconds, getSetpointReferenceVar()).
   }
   
   //Expects the following profile:
   //Apoapsis value beyond which the function will apply.  Full throttle prior.
   //Apoapsis value at which to shutdown.  Presumably the orbital altitude.
   declare function functionThrottler {
      local kickWithin is 1.5.
      if ship:apoapsis < launch_param["throttleProfile"][0] or eta:periapsis < eta:apoapsis return 1.
      else if ship:apoapsis > launch_param["throttleProfile"][1] return 0.
      else if vang(up:forevector, ship:facing:forevector) > 90-kickWithin and vang(up:forevector, ship:facing:forevector) < 90+kickWithin {
         //What am I doing here?  Okay, if ship:prograde is within 1 deg (either side) of horizontal...
         //function will return 0@89 deg, rise to 1@90 deg and fall to 0@91 deg. I.e. max thottle at horizontal prograde.
         //Adds the final kick to orbital altitude, if not there already. 
         //Max function ensures this will not cause throttling down, if already throttled up.
         return max(throttFunction(), -1*abs(vang(up:forevector, ship:prograde:forevector)-90)+kickWithin).
      } else {
         return throttFunction().
      }
   }

   declare function genericMonitor {
      //This prevents the program from shutting down if drag could still have an influence.
      if ship:apoapsis >= launch_param["throttleProfile"][1] and ((not (ship:orbit:body:atm:exists)) or ship:altitude > ship:orbit:body:atm:height)  {
         lock throttle to 0.
         return OP_FINISHED.
      }
      return OP_CONTINUE.
   }
}
