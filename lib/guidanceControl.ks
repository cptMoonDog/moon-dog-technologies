//James McConnel
//TODO doesn't account for cosine losses.
@LAZYGLOBAL off.
{
   runoncepath("general.ks").
   global guidance_ctl is lexicon().

   local burn_queue is queue().
   local start is 0.
   local end is 0.
             
   declare function hillclimb_patch {
      parameter mnode.
      parameter target.

      local step is 1.
      local last is mnode:orbit:nextpatch:periapsis.
      until false {
         if not mnode:orbit:hasnextpatch {
            clearscreen.
            print mnode.
            return OP_FINISHED.
         }
         local current is abs(target - mnode:orbit:nextpatch:periapsis).
         local right is 0.
         local left is 0.
         set mnode:prograde to mnode:prograde + step.
         if mnode:orbit:hasnextpatch set right to abs(target - mnode:orbit:nextpatch:periapsis).
         set mnode:prograde to mnode:prograde - step.
            
         set mnode:prograde to mnode:prograde - step.
         if mnode:orbit:hasnextpatch set left to abs(target - mnode:orbit:nextpatch:periapsis).
         set mnode:prograde to mnode:prograde + step.

         if (left = 0 AND right = 0) OR last <= current {
            if step < 0.0001 return OP_FINISHED.
            set step to step/2.
         } else if  current > right OR current > left {
            if right > left {
               set mnode:prograde to mnode:prograde + step.
            } else {
               set mnode:prograde to mnode:prograde - step.
            }
         } else {
            return OP_FINISHED.
         }
         set last to current.
      }
   }

   declare function transferFinder {
      parameter tgt is body("Mun").

      local t is time:seconds + 180.
      local radial is 0.
      local normal is 0.
      local pro is 0.
      local n is node(t, radial, normal, pro).

      local munPe is 2429600.
      local lastPe is 2429600.
      add(n).
      until false {
         if n:orbit:hasnextpatch {
            return hillclimb_patch(n, 10000).
            print "true munPe: "+n:orbit:nextpatch:periapsis at(0, 15).
            print "munPe: "+munPe at(0, 16).
            if n:orbit:nextpatch:periapsis < 10000 or lastPe < n:orbit:nextpatch:periapsis {
               return OP_FINISHED.
            }
            if n:orbit:nextpatch:periapsis < munPe {
               set munPe to n:orbit:nextpatch:periapsis.
            }else if n:orbit:nextpatch:periapsis > munPe {
              set lastPe to n:orbit:nextpatch:periapsis.
              set t to t + 1.
            }
         } else {
            if (n:orbit:apoapsis+ship:body:radius) < tgt:orbit:semimajoraxis {
               set pro to pro + 1.
            } else if (n:orbit:apoapsis+ship:body:radius) > tgt:orbit:semimajoraxis+1 {
               set pro to pro - 1.
            }
            if (n:orbit:apoapsis+ship:body:radius) >= tgt:orbit:semimajoraxis {
              set t to t + 1.
            }
         }
         set n:eta to t-time:seconds.
         set n:prograde to pro.
      }
      return OP_FINISHED.
   }
   guidance_ctl:add("findtransfer", transferFinder@).

   declare function phaseAngle {
      parameter startAlt.
      parameter finalAlt.

      local p is 1/(2*sqrt((finalAlt^3)/(((startAlt+finalAlt)/2)^3))).
      local angle is p*360.
      print angle at(0, 10).
      return angle.
   }
   declare function impulse_time {
      declare parameter ip.
      if ip = "ap" return time:seconds + eta:apoapsis.
      if ip = "pe" return time:seconds + eta:periapsis.
   }
   declare function lockto_impulse_direction {
      declare parameter dv.
      if dv = "circularize" lock steering to ship:prograde.
   }
   declare function get_dV {
      if burn_queue:peek()["dv"] = "circularize" 
         return phys_lib["OVatAlt"](Kerbin, ship:apoapsis) - phys_lib["VatAlt"](Kerbin, ship:apoapsis).
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

  declare function schedule_burn {
      declare parameter ip is "ap". //Acceptable values: ap, pe, rel, raw.
      declare parameter dv is "circularize". //Acceptable values: circularize, node, d_inclination, number
      declare parameter isp is 345. // Engine ISP
      declare parameter ff is 17.73419501.
      
      burn_queue:push(lexicon("ip", ip, "dv", dv, "isp", isp, "ff", ff)).
      reset_for_next_burn().
   }
   guidance_ctl:add("add_burn", schedule_burn@).
   
   declare function execute {
      print "T"+(time:seconds-start) at(1, 0).
      if start < time:seconds+180 AND start > time:seconds+10 { // between 3 minutes and 10 seconds out.
         lockto_impulse_direction(burn_queue:peek()["dv"]).
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
         burn_queue:pop().
         if burn_queue:empty return OP_FINISHED.
         else reset_for_next_burn().
      }
      return OP_CONTINUE.
   }
   guidance_ctl:add("burn_monitor", execute@).
}
