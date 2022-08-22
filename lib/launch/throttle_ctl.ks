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
         if mod(launch_param["throttleProfile"]:length, 2) > 0 {
            print "Error in throttle profile.  Odd number of data points.".
            shutdown.
         }
         lock throttle to getThrottleSetting_table().
         launch_ctl:add("throttle_monitor", throttleMonitor_table@).
      } else {
         if launch_param["throttleProgramType"] = "setpoint" {
            set throttFunction to thrott_function_setpoint@.
            set pid to PIDLOOP().
            set pid:setpoint to getValue_setpoint().
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
      else if launch_param["throttleReferenceVar"] = "etaAPO"
         return eta:apoapsis.
      else return 0.
   }
   //Utility function for the setpoint throttling system. Returns the Reference Value.
   declare function getReferenceValue_setpoint {
     if launch_param["throttleReferenceVar"] = "etaAPO"
        return eta:apoapsis.
     else if launch_param["throttleReferenceVar"] = "flightPathAngle"
        return (90-vang(ship:prograde:forevector, up:forevector)).//Angle of prograde vector from up.
      else return 0.
   }
   
   declare function getValue_setpoint {
      if launch_param["ThrottleProfile"][2] = "linearTangent" {
         return phys_lib["linearTan"](launch_param["throttleProfile"][1]).
      } else return launch_param["throttleProfile"][2].
   }

   /////// Monitors (A function that reports to the kernel during the zero-lift portion of the launch sequence.)
   // Monitors the value of the Reference Variable and advances through the table.
   // If a table based profile is selected by the lv, this will be exported as launch_ctl["throttleMonitor"]
   local step is 0.
   declare function throttleMonitor_table {
      //if ship:apoapsis < launch_param["throttleProfile"][launch_param["throttleProfile"]:length-1] {
      if ship:apoapsis < launch_param["targetApo"] {
         if step+2 < launch_param["throttleProfile"]:length-1 //Another step exists
            and getReferenceValue_table() > launch_param["throttleProfile"][step]
         { 
            set step to step+2.
         } else if step > 1 //A previous step exists
            and getReferenceValue_table() < launch_param["throttleProfile"][step-2]
         { 
            set step to step-2.
         }
         return OP_CONTINUE.
      } 
      //This prevents the program from shutting down if drag could still have an influence.
      if (not (ship:orbit:body:atm:exists)) or ship:altitude > ship:orbit:body:atm:height  {
         if launch_param:haskey("forceMECO") and launch_param["forceMECO"] = "true" {
            local engList is list().
            list engines in engList.
            for eng in engList 
               if eng:tag:tolower:contains("main") eng:shutdown.
         }
         return OP_FINISHED.
      }
      return OP_CONTINUE.
   }
   // If shutdown condition reached, cut throttle, but stay alive until above atmosphere.
   // If a function or setpoint based profile is selected by the lv, this will be exported as launch_ctl["throttleMonitor"]
   declare function throttleMonitor_function {
      //This prevents the program from shutting down if drag could still have an influence.
      if ship:apoapsis >= launch_param["throttleProfile"][1] and ((not (ship:orbit:body:atm:exists)) or ship:altitude > ship:orbit:body:atm:height)  {
         lock throttle to 0.
         if launch_param:haskey("forceMECO") and launch_param["forceMECO"] = "true" {
            local engList is list().
            list engines in engList.
            for eng in engList 
               if eng:tag:tolower:contains("main") eng:shutdown.
         }
         return OP_FINISHED.
      }
      return OP_CONTINUE.
   }

   //////// Throttle setters (Functions that throttle can be locked to.)
   local kickWithin is 2.5.
   //Returns the throttle setting
   // If a table based profile is selected by the lv, the throttle will be locked to this function.
   // Expects a table of throttle values vs a reference variable (altitude, Apoapsis, MET, etc) in launch_param["throttleProfile"]
   // Ex. If the reference variable is altitude, you might have:
   // Altitude | Throttle setting
   //  2000    |    1
   //  34000   |    0.5
   //  70000   |    0.1
   declare function getThrottleSetting_table {
      //if ship:apoapsis > launch_param["throttleProfile"][launch_param["throttleProfile"]:length-1] {
      if ship:apoapsis > launch_param["targetApo"] {
         return 0.
      } else if step = 0 {
         return launch_param["throttleProfile"][step+1].
      } else {
         if getReferenceValue_table() > launch_param["throttleProfile"][launch_param["throttleProfile"]:length-2]*0.99 { // Reference > last full point
            if getReferenceValue_table() > launch_param["throttleProfile"][launch_param["throttleProfile"]:length-2] return 0.
            else return max(0, 0.01+1-getReferenceValue_table()/launch_param["throttleProfile"][launch_param["throttleProfile"]:length-2]).
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
      local defaultSetting is 1.
         if launch_param["throttleProfile"]:length = 3 // If a setpoint, or parameter for the function is provided, pass it.
            // Reason for max function is that in some unusual cases the if allowed to throttle very low, 
            // thrust can balance with drag so well, that orbit is never achieved and as long as the fuel lasts
            // you effectively have an in atmosphere orbit.
            set defaultSetting to max(0.01, throttFunction(launch_param["throttleProfile"][2])).
         else
            set defaultSetting to max(0.01, throttFunction()). 
      if ship:apoapsis < launch_param["throttleProfile"][0] or eta:periapsis < eta:apoapsis return 1.
      else if ship:apoapsis > launch_param["throttleProfile"][1]*0.99 {
         if ship:apoapsis > launch_param["throttleProfile"][1] {
            return 0.
         } else {
            return max(0.01, ((1 - min(1, ship:apoapsis/launch_param["throttleProfile"][1]))+(1 - min(1, ship:altitude/ship:body:atm:height)))/2).
         }
      //} else if vang(up:forevector, ship:facing:forevector) > 90-kickWithin and vang(up:forevector, ship:facing:forevector) < 90+kickWithin {
      } else if vang(up:forevector, ship:prograde:forevector) > 90-kickWithin and vang(up:forevector, ship:prograde:forevector) < 90+kickWithin {
         //What am I doing here?  Okay, if ship:prograde is within 1 deg (either side) of horizontal...
         //function will return 0@89 deg, rise to 1@90 deg and fall to 0@91 deg. I.e. max thottle at horizontal prograde.
         //Adds the final kick to orbital altitude, if not there already. 
         //Max function ensures this will not cause throttling down, if already throttled up.
         local driveToOrbit is {// final push to apoapsis; use that oberth
            parameter throwaway is 0.
            // 
            return max(0.01, max(1-(ship:apoapsis/launch_param["throttleProfile"][1]), ship:availablethrust/(eta:apoapsis*ship:mass))).
         }. 
         if driveToOrbit() > defaultSetting set throttFunction to driveToOrbit.
         return max(defaultSetting, 1 - abs(vang(up:forevector, ship:prograde:forevector) - 90)/kickWithin).
      } else return defaultSetting.
   }

   ///////// Misc
   //Utility to make getThrottleSetting_table easier
   declare function smoothInterval {
      parameter top.
      parameter bottom.
      parameter current.
      parameter outputRange.

      return ((max(bottom, min(top, current))-bottom)/(top-bottom))*outputRange.
   }

   //Returns the throttle setting
   // If a setpoint based profile is selected by the lv, this will be the throttFunction.
   declare function thrott_function_setpoint {
      parameter throwaway is eta:apoapsis.
      //Variable setpoints
      set pid:setpoint to getValue_setpoint().
      if ship:apoapsis > launch_param["throttleProfile"][1] return pid:update(time:seconds, getReferenceValue_setpoint()). 
      return pid:update(time:seconds, getReferenceValue_setpoint()).
   }
   
     

}
