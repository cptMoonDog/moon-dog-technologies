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
      declare parameter ip is "ap". //Acceptable values: ap, pe, rel, raw.
      declare parameter dv is "circularize". //Acceptable values: circularize, node, d_inclination, number
      declare parameter isp is 345. // Engine ISP
      declare parameter ff is 17.73419501.
      declare parameter steeringProgram is "prograde".

      local program is 0.
      if steeringProgram = "prograde" set program to {return ship:prograde.}.
      else set program to steeringProgram.
      
      burn_queue:push(lexicon("ip", ip, "dv", dv, "isp", isp, "ff", ff, "steeringProgram", program)).
      reset_for_next_burn().
   }
   maneuver_ctl:add("add_burn", schedule_burn@).
   
   declare function execute {
      if start > time:seconds+180 {
         if kuniverse:timewarp:warp = 0 and kuniverse:timewarp:rate = 1 and Kuniverse:timewarp:issettled() {
            kuniverse:timewarp:warpto(start-181).
         }
         return OP_CONTINUE.
      }
      reset_for_next_burn().
      if start < time:seconds+180 AND start > time:seconds+10 { // between 3 minutes and 10 seconds out.
         lock steering to burn_queue:peek()["steeringProgram"]().
      }
      if start < time:seconds+30 AND start > time:seconds+25 {
         reset_for_next_burn(). // recalculates to improve precision
         lock throttle to 0.
         print "recalculating..." at(0, 10).
      }
      print "T-"+(start-time:seconds) at(0, 11).
      if  start <= time:seconds AND time:seconds < start+10 { // Will only attempt to lock throttle for 10 seconds.
         lock throttle to 1.
         print "throttle: "+ throttle at(0, 15).
      }
      if end <= time:seconds {
         lock throttle to 0.
         unlock steering.
         burn_queue:pop().
         if burn_queue:empty {
            print "burn finished".
            return OP_FINISHED.
         } else reset_for_next_burn().
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
      return ship:mass*(constant:e^(-((get_dV()/2)/(burn_queue:peek()["isp"]*phys_lib["g0"])))).
   }
   declare function burn_length_first_half {
      return ((ship:mass-m2())/(burn_queue:peek()["ff"]/1000)).
   }
   declare function burn_length_second_half {
      local m3 is m2()/(constant:e^((get_dV()/2)/(burn_queue:peek()["isp"]*phys_lib["g0"]))).
      return ((m2()-m3)/(burn_queue:peek()["ff"]/1000)).
   }

   declare function reset_for_next_burn {
      set start to impulse_time(burn_queue:peek()["ip"]) - burn_length_first_half().
      set end to impulse_time(burn_queue:peek()["ip"]) + burn_length_second_half().
   }

}


