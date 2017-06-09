@lazyglobal off.
{
   global range_ctl is lexicon().
   local count is 10.

   declare function init {
      parameter c.
      set count to c.
   }
   range_ctl:add("init", init@).

   local lastTime is time:seconds-1.
   declare function do_countdown {
      parameter type.
      if type = "a" { //arbitrary
         if count > -1 and time:seconds-lastTime > 1 {
            hudtext(count+"...", 1, 2, 20, white, false).
            set count to count - 1.
            set lastTime to time:seconds.
            return OP_CONTINUE.
         } else if count < 0 {
            return OP_FINISHED.
         } else return OP_CONTINUE.
      }
      if type = "w" { //window
         local ttw is time_to_window(minmus:orbit:LAN, minmus:orbit:inclination, 130, "south").
         if ttw:seconds > 180 {
            if kuniverse:timewarp:warp = 0 and kuniverse:timewarp:rate <= 1 {
               kuniverse:timewarp:warpto(time:seconds+ttw:seconds - 179).
            }
            return OP_CONTINUE.
         }
         if time:seconds-lastTime > 1 {
            hudtext("T-"+ttw:clock, 1, 2, 20, white, false).
            set lastTime to time:seconds.
         } 
         if ttw:seconds < 0.01 {
            return OP_FINISHED.
         } else return OP_CONTINUE.
      }
   }
   range_ctl:add("countdown", (do_countdown@):bind("w")).

   declare function normalizeAngle {
      parameter theta.
      if theta < 0 return theta + 360.
      else return theta.
   }

   declare function time_to_window {
      parameter RAAN. //LAN
      parameter i. //inclination
      parameter tof. //Time of Flight, correction factor, need to call it something.
      parameter allowable is "all". 

      //Longitude correction of launch window due to latitude.
      local lonOffset is arcsin(tan(ship:latitude)/tan(i)).
      local astroLon is normalizeAngle((ship:orbit:body:rotationangle+ship:longitude)).
      local degFromAN is normalizeAngle(astroLon - RAAN).
      local degToDN is normalizeAngle((180-degFromAN)-lonOffset).
      local degToAN is normalizeAngle((360-degFromAN)+lonOffset).

      if allowable = "all" {
         if degToDN < degToAN {
            return time-time+(ship:orbit:body:rotationperiod/360)*degToDN-tof.
         } else {
            return time-time+(ship:orbit:body:rotationperiod/360)*degToAN-tof.
         }
      } else if allowable = "north" {
         return time-time+(ship:orbit:body:rotationperiod/360)*degToAN-tof.
      } else {
         return time-time+(ship:orbit:body:rotationperiod/360)*degToDN-tof.
      }
   }
}
