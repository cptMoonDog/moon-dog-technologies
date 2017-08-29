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
   
   declare function launchAzimuth {
      parameter inclination is 90.
      parameter hemisphere is "north".

      local south is false.
      if hemisphere = "south" set south to true.

      local atmHeight is 0.
      if ship:body:atm:exists
         set atmHeight to ship:body:atm:height.
      local OV is phys_lib["OVatAlt"](ship:body, atmHeight). //Kerbin, 70000).//orbit_parameters["altitude"]).

      //It is impossible to launch into an orbit with an inclination < the latitude at the launch site, so if necessary ignore the inclination parameter.
      //Therefore acceptable inclinations are >= abs(latitude) and <= 180-abs(latitude).
      //TODO Maybe not a good idea clobbering an input value, but on the other hand, this value will need to be corrected program wide.
      //Would it be better to throw an error and force user intelligence?
      if abs(ship:latitude) > inclination set inclination to abs(ship:latitude).
      else if abs(ship:latitude)+inclination  > 180 set inclination to 180-abs(ship:latitude).
      
      local inertialAzimuth is arcsin(cos(inclination)/cos(ship:latitude)).

      //Adjust the IA to a valid compass heading.
      if south { 
         if inertialAzimuth < 0 { 
            set inertialAzimuth to -180-inertialAzimuth.
         } else set inertialAzimuth to 180-inertialAzimuth. 
      } 
      if inertialAzimuth < 0 set inertialAzimuth to 360+inertialAzimuth.
      //Here we give up precision for the sake of correctness.
      if inertialAzimuth < 0.0001 and inertialAzimuth > -0.0001 set inertialAzimuth to 0.
      if inertialAzimuth < 90.001 and inertialAzimuth > 89.999 set inertialAzimuth to 90.

      //Should be the circumference of the cirle of latitude divided by the sidereal rotation period.
      local Vrot is (2*constant:pi*(body:radius+ship:altitude)*cos(ship:latitude))/body:rotationperiod.
      local Vx is OV*sin(inertialAzimuth)-Vrot.
      local Vy is OV*cos(inertialAzimuth).
      local rotatingAzimuth is 0.

      //Trig functions generally do not return exactly 0, even if they did, Vy=0 would produce a div by zero error.
      //Also, microscopic values of Vy that are < 0, will produce +90.
      if south {
         //inclination: 0
         if Vx < 0 and Vy < 0.0001 and Vy > -0.0001 set rotatingAzimuth to 90.
         //inclination: 180
         else if Vx > 0 and Vy < 0.0001 and Vy > -0.0001 set rotatingAzimuth to -90.
         //inclination: everything else
         else set rotatingAzimuth to arctan(Vx/Vy).
         return 180+rotatingAzimuth.
      } else {
         //inclination: 180
         if Vx < 0 and Vy < 0.0001 and Vy > -0.0001 set rotatingAzimuth to -90.
         //inclination: 0
         else if Vx > 0 and Vy < 0.0001 and Vy > -0.0001 set rotatingAzimuth to 90.
         //inclination: everything else
         else set rotatingAzimuth to arctan(Vx/Vy).
         if rotatingAzimuth < 0 return 360+rotatingAzimuth.
         else return rotatingAzimuth.
      }
   }
   range_ctl:add("launchAzimuth", launchAzimuth@).
}
