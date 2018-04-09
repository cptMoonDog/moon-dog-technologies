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
      if launch_param["throttleProgramType"] = "tableMET" {
         lock throttle to throttleSmoother().
         launch_ctl:add("throttle_monitor", advanceStep@).
      } else if launch_param["throttleProgramType"] = "tableAPO" {
         lock throttle to throttleSmoother().
         launch_ctl:add("throttle_monitor", advanceStep@).
      } else if launch_param["throttleProgramType"] = "etaApo" {
         set throttFunction to thrott_function_etaAPO@.
         lock throttle to functionThrottler().
         set pid to PIDLOOP().
         set pid:setpoint to launch_param["throttleProfile"][2].
         set pid:minoutput to 0.
         set pid:maxoutput to 1.
         launch_ctl:add("throttle_monitor", genericMonitor@).
      } else if launch_param["throttleProgramType"] = "vOV" {
         set throttFunction to thrott_function_vOV@.
         lock throttle to functionThrottler().
         launch_ctl:add("throttle_monitor", genericMonitor@).
      }
     // else if launch_param["throttleProgramType"] = "constVTWR" {
     //    set throttFunction to thrott_function_constantVerticalTWR@.
     //    lock throttle to functionThrottler().
     //    set pid to PIDLOOP().
     //    set pid:setpoint to launch_param["throttleProfile"][2].
     //    set pid:minoutput to 0.
     //    set pid:maxoutput to 1.
     //    launch_ctl:add("throttle_monitor", genericMonitor@).
     // }
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
      if ship:apoapsis >= launch_param["throttleProfile"][1] and ((not (ship:orbit:body:atm:exists)) or ship:altitude > ship:orbit:body:atm:height)  {
         lock throttle to 0.
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
      if launch_param["throttleProgramType"] = "tableMET"
         return MISSIONTIME.
      else if launch_param["throttleProgramType"] = "tableAPO"
         return ship:apoapsis.
      else return 0.
   }

 ///Non-table based throttling methods.
   declare function thrott_function_etaAPO {
      return pid:update(time:seconds, eta:apoapsis).
   }
   //Throttle setting is the inverse ratio of the horizontal component of orbital velocity and orbital velocity at the current altitude.
   declare function thrott_function_vOV {
      return 1-sin(vang(up:forevector, facing:forevector))*(ship:velocity:orbit:mag/phys_lib["OVatAlt"](Kerbin, ship:altitude)).
   }
   //DO NOT USE, doesn't work.
   declare function thrott_function_constantVerticalTWR {
      local rval is pid:update(time:seconds, lastThrottVal*((ship:availablethrust/(ship:mass*9.807))*cos(vang(up:forevector, facing:forevector)))).
      set lastThrottVal to rval.
      return rval.
   }
   
   //Expects the following profile:
   //Apoapsis value beyond which the function will apply.  Full throttle prior.
   //Apoapsis value at which to shutdown.  Presumably the orbital altitude.
   declare function functionThrottler {
      if ship:apoapsis < launch_param["throttleProfile"][0] or eta:periapsis < eta:apoapsis return 1.
      else if ship:apoapsis > launch_param["throttleProfile"][1] return 0.
      else if vang(up:forevector, ship:facing:forevector) > 89 and vang(up:forevector, ship:facing:forevector) < 91 {
         //What am I doing here?  Okay, if ship:prograde is within 1 deg (either side) of horizontal...
         //function will return 0@89 deg, rise to 1@90 deg and fall to 0@91 deg. I.e. max thottle at horizontal prograde.
         //Adds the final kick to orbital altitude, if not there already. 
         //Max function ensures this will not cause throttling down, if already throttled up.
         local kickWithin is 2.
         return max(throttFunction(), -1*abs(vang(up:forevector, ship:prograde:forevector)-90)+kickWithin).
      } else {
         return throttFunction().
      }
   }
}
