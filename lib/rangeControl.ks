@lazyglobal off.
{
   global range_ctl is lexicon().
   local window_params is lexicon("lan", 0, "inclination", 0, "tof", 0, "hemisphere", "north").
   local count is 10.

   declare function init {
      parameter w.
      if w:istype("Lexicon") {
         set window_params to w.
         if window_params["inclination"] < abs(ship:latitude) {
            set window_params["inclination"] to abs(ship:latitude).
         }
         range_ctl:add("countdown", countdown_launchWindow@).
      } else if w:istype("Scalar") {
         set count to w.
         range_ctl:add("countdown", countdown_scalar@).
      }
   }
   range_ctl:add("init", init@).

   //
   local lastTime is time:seconds-1.
   declare function countdown_scalar {
      if count > -1 and time:seconds-lastTime > 1 {
         hudtext(count+"...", 1, 2, 20, white, false).
         set count to count - 1.
         set lastTime to time:seconds.
         return OP_CONTINUE.
      } else if count < 0 {
         return OP_FINISHED.
      } else return OP_CONTINUE.
   }

   declare function countdown_launchWindow {
      local ttw is time_to_window(window_params["lan"], window_params["inclination"], window_params["tof"], window_params["hemisphere"]).
      print ttw at(0,7).
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

   declare function normalizeAngle {
      parameter theta.
      if theta < 0 return theta + 360.
      else return theta.
   }

   declare function time_to_window {
      parameter RAAN. //LAN
      parameter i. //inclination
      parameter tof. //Time of Flight, the amount of time from launch to achievement of inclination.
      parameter allowable is "all". 

      //Longitude correction of launch window due to latitude.
      print ship:latitude.
      print i.
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
