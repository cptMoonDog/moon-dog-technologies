@lazyglobal off.
{
   /// This library's list of  exported functions.
   if not (defined launch_ctl)
      global launch_ctl is lexicon().

   local countdown is 180.
   local lastTime is time:seconds.
   local timeOfWindow is 0. 
   local V0 is getvoice(0).
   
   declare function init {

      if launch_param["inclination"] < abs(ship:latitude) {
         set launch_param["inclination"] to abs(ship:latitude).
      }

      if launch_param:haskey("countdownLength") set countdown to launch_param["countdownLength"].

      launch_ctl:add("countdown", countdown_launchWindow@).
      if launch_param["launchTime"] = "window" {              //Will warp to (window time - countdown), then countdown and launch.
         set timeOfWindow to getUT_window(launch_param["lan"], 
                                          launch_param["inclination"], 
                                          launch_param["timeOfFlight"], 
                                          launch_param["azimuthHemisphere"]).
      } else if launch_param["launchTime"] = "now" {          //Will countdown and launch.
         if launch_param:haskey("orbitType") and launch_param["orbitType"] = "rendezvous" {
            print etaPhaseAngle() at(0, 10).
            set timeOfWindow to time:seconds+etaPhaseAngle().
            launch_param:add("targetApo", target:orbit:periapsis).
         } else set timeOfWindow to time:seconds + countdown + 1.
      } else if launch_param["launchTime"]:istype("Scalar") { //Will warp to (Utime - countdown), then countdown and launch.
         set timeOfWindow to launch_param["launchTime"].
      }
   }
   launch_ctl:add("init_range", init@).

      
   declare function countdown_launchWindow {
      if timeOfWindow-time:seconds > countdown+1 {
         if kuniverse:timewarp:warp = 0 and kuniverse:timewarp:rate = 1 and Kuniverse:timewarp:issettled() {
            kuniverse:timewarp:warpto(timeOfWindow - countdown).
         }
         return OP_CONTINUE.
      }
      if time:seconds-lastTime > 1 {
         hudtext("T-"+timespan(timeOfWindow-time:seconds):second+"...", 1, 2, 20, white, false).//Time arithmetic casts to TimeSpan object
         if timeOfWindow-time:seconds < 11 {
            if timeOfWindow-time:seconds > 1 {
               //V0:play(note("C5", 0.1)).
            } 
         }
         set lastTime to time:seconds.
      } 
      if timeOfWindow-time:seconds < 0.01 {
         V0:play(note("C5", 1)).
         return OP_FINISHED.
      } else return OP_CONTINUE.
   }

   declare function normalizeAngle {
      parameter theta.
      if theta < 0 return theta + 360.
      else return theta.
   }

   declare function getUT_window {
      parameter RAAN. //LAN
      parameter i. //inclination
      parameter tof. //Time of Flight, the amount of time from launch to achievement of inclination fudge factor :.
      parameter allowableTrajectories is "all". 

      //Longitude correction of launch window due to latitude.
      local lonOffset is arcsin(min(1, tan(ship:latitude)/tan(i))). //min function prevents NAN
      local astroLon is normalizeAngle((ship:orbit:body:rotationangle+ship:longitude)).
      local degFromAN is normalizeAngle(astroLon - RAAN).
      local degToDN is normalizeAngle((180-degFromAN)-lonOffset).
      local degToAN is normalizeAngle((360-degFromAN)+lonOffset).

      if allowableTrajectories = "all" or allowableTrajectories = "any" {  /////////////Arithmetic on TIME below functions as a defacto cast to object of type TIME.
         if degToDN < degToAN {
            set launch_param["azimuthHemisphere"] to "south".
            return time:seconds+(ship:orbit:body:rotationperiod/360)*degToDN-tof.
         } else {
            set launch_param["azimuthHemisphere"] to "north".
            return time:seconds+(ship:orbit:body:rotationperiod/360)*degToAN-tof.
         }
      } else if allowableTrajectories = "north" {
         return time:seconds+(ship:orbit:body:rotationperiod/360)*degToAN-tof.
      } else {
         return time:seconds+(ship:orbit:body:rotationperiod/360)*degToDN-tof.
      }
   }  
   
   declare function launchAzimuth {

      local south is false.
      if launch_param["azimuthHemisphere"] = "south" set south to true.

      local atmHeight is 0.
      if ship:body:atm:exists
         set atmHeight to ship:body:atm:height.
      local OV is phys_lib["OVatAlt"](ship:body, atmHeight). //Kerbin, 70000).//orbit_parameters["altitude"]).

      //It is impossible to launch into an orbit with an inclination < the latitude at the launch site, so if necessary ignore the inclination parameter.
      //Therefore acceptable inclinations are >= abs(latitude) and <= 180-abs(latitude).
      //TODO Maybe not a good idea clobbering an input value, but on the other hand, this value will need to be corrected program wide.
      //Would it be better to throw an error and force user intelligence?
      if abs(ship:latitude) > launch_param["inclination"] set launch_param["inclination"] to abs(ship:latitude).
      else if abs(ship:latitude)+launch_param["inclination"]  > 180 set launch_param["inclination"] to 180-abs(ship:latitude).
      
      local inertialAzimuth is arcsin(min(1, cos(launch_param["inclination"])/cos(ship:latitude))). //min function prevents NAN

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
   launch_ctl:add("launchAzimuth", launchAzimuth@).

   declare function currentPhaseAngle {
      // From: https://forum.kerbalspaceprogram.com/index.php?/topic/85285-phase-angle-calculation-for-kos/
      //Assumes orbits are both in the same plane.
      // And that that plane is equatorial
      declare parameter t is target.
      local a1 is ship:longitude.
      local a2 is 0.
      if t:istype("Orbitable") {
         set a2 to t:orbit:lan+t:orbit:argumentofperiapsis+t:orbit:trueanomaly.
      } else {
         set a2 to t.
      }
       
      local diff is a2-a1.
      set diff to diff-360*floor(diff/360).
      return diff.
   }

   declare function etaPhaseAngle {
      declare parameter t is target.
      local rateShip is 360/ship:orbit:body:rotationperiod.
      local rateTarget is 0.
      local pa is 0.
      set pa to phaseAngle(ship:orbit:body:radius+ship:altitude, target:orbit:semimajoraxis).
      set rateTarget to 360/target:orbit:period.
      
      local current is currentPhaseAngle(t).

     // // I want some time to burn my engines, so I need to lead a bit to have time
     // // I'm sure there is a better way to do this, but for now...
     // local minDiff is 20.
     // 
     // local diff is  0.
     // if pa > current-minDiff {
     //    set diff to 360+current-pa.
     // } else set diff to current-pa.

     // if diff < 0 set diff to diff+360.
      local dist is 360-pa.
      local diff is (360-pa) - current.

      local tm is (diff)/(rateTarget-rateShip).
      set tm to tm - 0. //Fudge Factor 
      return tm.

   }

   declare function phaseAngle {
      parameter startAlt.
      parameter finalAlt.

      local p is 1/(2*sqrt((finalAlt^3)/(((startAlt+finalAlt)/2)^3))).
      local angle is p*360.
      return 180-angle.
   }
}
