//James McConnel
//TODO doesn't account for cosine losses.

//Tue Jun 20 21:18:31 PDT 2017
@LAZYGLOBAL off.
{
   global maneuver_ctl is lexicon().

   local burn_queue is queue().
   local start is 0.
   local end is 0.
   local currentNode is 0.

///Public functions

   declare function schedule_burn {
      declare parameter steeringProgram. // A string indicating direction ("prograde", "retrograde", "normal", "antinormal", etc) 
      declare parameter engineName.
      declare parameter impulsePoint.    // Acceptable values: ap, pe, AN, DN, raw time. 
      declare parameter dv is 0.              // Acceptable values: circularize, d_inclination, scalar

      local program is 0.
      if steeringProgram = "prograde" set program to {return ship:prograde.}.
      else if steeringProgram = "retrograde" set program to {return ship:retrograde.}.
      else if steeringProgram = "normal" set program to {return ship:normal.}.
      else if steeringProgram = "antinormal" set program to {return ship:antinormal.}.
      else if steeringProgram = "radial" set program to {return ship:radial.}.
      else if steeringProgram = "antiradial" set program to {return ship:antiradial.}.
      else if steeringProgram = "node" set program to {return currentNode:burnVector.}.
      else set program to steeringProgram.

      if impulsePoint = "node" {
         set currentNode to nextnode.
         burn_queue:push(lexicon("ip", time:seconds+nextnode:eta, "dv", nextnode:deltaV:mag, "isp", engineStat(engineName, "isp"), "ff", engineStat(engineName, "ff"), "steeringProgram", program)).
      } else burn_queue:push(lexicon("ip", impulsePoint, "dv", dv, "isp", engineStat(engineName, "isp"), "ff", engineStat(engineName, "ff"), "steeringProgram", program)).
      reset_for_next_burn().
   }
   maneuver_ctl:add("add_burn", schedule_burn@).

   declare function execute {
      if burn_queue:empty {
         print "No burn loaded!!!".
         return OP_FINISHED.
      }
      if time:seconds < start print "T-"+(start-time:seconds) at(0, 10).
      else print "T+"+(time:seconds-start) at(0, 10).
      //Over 3 minutes out, warp
      if time:seconds < start-180 { 
         if kuniverse:timewarp:warp = 0 and kuniverse:timewarp:rate = 1 and Kuniverse:timewarp:issettled() {
            kuniverse:timewarp:warpto(start-179).
         }
      //Less than 3 minutes out and more than 30 sec, attempt to lock steering
      } else if time:seconds > start-180 AND time:seconds < start-30 { 
         lock steering to burn_queue:peek()["steeringProgram"]().
      //Less than 30 sec out and more than 25 sec, recalculate burn timing.
      } else if time:seconds > start-30 AND time:seconds < start-25 { 
         reset_for_next_burn(). // recalculates to improve precision
         lock throttle to 0.
      //Start of burn. Continue attempting to lock throttle until end of scheduled burn unless already locked.
      } else if  time:seconds >= start AND time:seconds < end AND throttle = 0 { 
         lock throttle to 1.
      //Burn finished.  Engine shutdown.  Wait 5 seconds, then queue up next burn.
      } else if time:seconds >= end { 
         lock throttle to 0.
         unlock steering.
         if time:seconds > end+5 { 
            burn_queue:pop().
            if currentNode <> 0 and hasnode {
                  remove nextnode.
            }
            if burn_queue:empty {
               return OP_FINISHED.
            } else reset_for_next_burn().
         }  
      }
      return OP_CONTINUE.
   }
   maneuver_ctl:add("burn_monitor", execute@).


///Private functions
             
   declare function impulse_time {
      declare parameter ip.
      if ip:istype("Scalar") return ip.
      if ip = "ap" return time:seconds + eta:apoapsis.
      if ip = "pe" return time:seconds + eta:periapsis.
   }
   declare function get_dV {
      if burn_queue:peek()["dv"] = "circularize" {
         local impulseAlt is 0.
         if burn_queue:peek()["ip"] = "ap" set impulseAlt to ship:apoapsis.
         else set impulseAlt to ship:periapsis.
         return abs(phys_lib["OVatAlt"](ship:orbit:body, impulseAlt) - phys_lib["VatAlt"](ship:orbit:body, impulseAlt, ship:orbit:semimajoraxis)).
      } else if burn_queue:peek()["dv"]:istype("Scalar") {
         return burn_queue:peek()["dv"].
      }
   }
   
   declare function reset_for_next_burn {
      //Better non-impulsive burn timing: apply half the dV before and half the dV after the impulse point.
      local m2 is ship:mass*1000*(constant:e^(-((get_dV()/2)/(burn_queue:peek()["isp"]*g0)))).
      local burnLengthFirstHalf is ((ship:mass*1000-m2)/(burn_queue:peek()["ff"])).
      local m3 is m2/(constant:e^((get_dV()/2)/(burn_queue:peek()["isp"]*g0))).
      local burnLengthSecondHalf is ((m2-m3)/(burn_queue:peek()["ff"])).

      set start to impulse_time(burn_queue:peek()["ip"]) - burnLengthFirstHalf.
      set end to impulse_time(burn_queue:peek()["ip"]) + burnLengthSecondHalf.
   }

   declare function engineStat {
      declare parameter name.
      declare parameter stat.
      local isp is 0.
      local thrust is 0.
      if name="bollard" {
         set isp to 325.
         set thrust to 925.
      }
      if name="terrier" {
         set isp to 345.
         set thrust to 60.
      }
      if name="skipper" {
         set isp to 320.
         set thrust to 650.
      }
      if name="doubleThud" {
         set isp to 305.
         set thrust to 240.
      }
      if stat="isp" return isp.
      if stat="thrust" return thrust.
      if stat="ff" return thrust*1000/(isp*9.80665).

      //Fail 
      print "ENGINE: "+name+" DOES NOT EXIST IN THE DB.".
      print "COUGH...COUGH...GURGLE...GURGLE.".
      print "You watch helplessly as *NPC Name here* dies in your arms.".
      set OP_FAIL to true.
   }
   maneuver_ctl:add("upperStage_stat", engineStat@).
}


