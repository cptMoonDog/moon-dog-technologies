//James McConnel
//TODO doesn't account for cosine losses.

//Tue Jun 20 21:18:31 PDT 2017
@LAZYGLOBAL off.
//runoncepath("general.ks").
{
   global maneuver_ctl is lexicon().

   local burn_queue is queue().
   local start is 0.
   local end is 0.

///Public functions

  declare function schedule_burn {
      declare parameter impulsePoint is "ap". //Acceptable values: ap, pe, raw time, true anomaly angle. 
      declare parameter dv is "circularize". //Acceptable values: circularize, node, d_inclination, number
      declare parameter isp is 345. // Engine ISP
      declare parameter ff is 17.73419501.
      declare parameter steeringProgram is "prograde".

      local program is 0.
      if steeringProgram = "prograde" set program to {return ship:prograde.}.
      else set program to steeringProgram.
      
      burn_queue:push(lexicon("ip", impulsePoint, "dv", dv, "isp", isp, "ff", ff, "steeringProgram", program)).
      reset_for_next_burn().
   }
   //maneuver_ctl:add("add_burn", schedule_burn@).


   declare function schedule_node {
      declare parameter n.
      declare parameter isp.
      declare parameter ff.
      declare parameter steeringProgram.

      local program is 0.
      if steeringProgram = "prograde" set program to {return ship:prograde.}.
      else if steeringProgram = "node" set program to {return nextnode:burnvector.}.
      else set program to steeringProgram.
      
      burn_queue:push(lexicon("ip", n:eta+time:seconds, "dv", n:deltav:mag, "isp", isp, "ff", ff, "steeringProgram", program)).
      reset_for_next_burn().
   }
   maneuver_ctl:add("add_burn", schedule_node@).
   
   declare function execute {
      if time:seconds < start print "T-"+start-time:seconds at(0, 10).
      else print "T+"+time:seconds-start at(0, 10).
      //Over 3 minutes out, warp
      if time:seconds < start-180 { //start > time:seconds+180 {
         if kuniverse:timewarp:warp = 0 and kuniverse:timewarp:rate = 1 and Kuniverse:timewarp:issettled() {
            kuniverse:timewarp:warpto(start-181).
         }
      //Less than 3 minutes out and more than 30 sec, attempt to lock steering
      } else if time:seconds > start-180 AND time:seconds < start-30 { //start < time:seconds+180 AND start > time:seconds+30 { // between 3 minutes and 10 seconds out.
         lock steering to burn_queue:peek()["steeringProgram"]().
      //Less than 30 sec out and more than 25 sec, recalculate burn timing.
      } else if time:seconds > start-30 AND time:seconds < start-25 { //start < time:seconds+30 AND start > time:seconds+25 {
         reset_for_next_burn(). // recalculates to improve precision
         lock throttle to 0.
      //Start of burn. Continue attempting to lock throttle until end of scheduled burn unless already locked.
      } else if  time:seconds >= start AND time:seconds < end AND throttle = 0 { //start <= time:seconds AND time:seconds < end AND throttle = 0 { 
         lock throttle to 1.
      //Burn finished.  Engine shutdown.  Wait 5 seconds, then queue up next burn.
      } else if time:seconds >= end { //end <= time:seconds {
         lock throttle to 0.
         unlock steering.
         if time:seconds > end+5 { //end < time:seconds-5 {
            burn_queue:pop().
            if burn_queue:empty {
               return OP_FINISHED.
            } else reset_for_next_burn().
         } else 
      }
      return OP_CONTINUE.
   }
   maneuver_ctl:add("burn_monitor", execute@).


///Private functions
             
   declare function impulse_time {
      declare parameter ip.
      if ip = "ap" return time:seconds + eta:apoapsis.
      if ip = "pe" return time:seconds + eta:periapsis.
   }
   declare function get_dV {
      if burn_queue:peek()["dv"] = "circularize" 
         return phys_lib["OVatAlt"](Kerbin, ship:apoapsis) - phys_lib["VatAlt"](Kerbin, ship:apoapsis).
      else if burn_queue:peek()["dv"]:istype("Scalar") {
         return burn_queue:peek()["dv"].
      }
   }
   
   ///////Functions for calculating a better non-impulsive maneuver.
   //mass after first half of burn
   declare function m2 {
      return ship:mass*1000*(constant:e^(-((get_dV()/2)/(burn_queue:peek()["isp"]*phys_lib["g0"])))).
   }
   declare function burn_length_first_half {
      return ((ship:mass*1000-m2())/(burn_queue:peek()["ff"])).
   }
   declare function burn_length_second_half {
      local m3 is m2()/(constant:e^((get_dV()/2)/(burn_queue:peek()["isp"]*phys_lib["g0"]))).
      return ((m2()-m3)/(burn_queue:peek()["ff"])).
   }

   declare function reset_for_next_burn {
      set start to impulse_time(burn_queue:peek()["ip"]) - burn_length_first_half().
      set end to impulse_time(burn_queue:peek()["ip"]) + burn_length_second_half().
      print "burn length: "+(end-start) at(0, 10).
   }

}


