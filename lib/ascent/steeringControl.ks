//SteeringControl.ks
//Handles steering during rocket ascent.
//James McConnel
// TODO allow steering to fix inclination after locking to prograde.  Currently does not adjust when it overshoots.
//FYI's :
// Orbital inclination is never reported in practice as more that 180.  
// Launching South then, is in practice indistinguishable from launching North, at least orbit wise.
// However, this script will accept larger "inclinations" in order to support launching South.
@LAZYGLOBAL off.
{

   runoncepath("general.ks").

   global steering_ctl is lexicon().
   local orbit_parameters is lexicon("altitude", 80000, "inclination", 90, "pOverDeg", 4, "pOverV0", 30, "pOverVf", 150).

   local a is 0.
   local azimuth is 0.
   declare function init {
      parameter p.
      if p:istype("Lexicon") {
         set orbit_parameters to p.
      }
      set a to ship:altitude.
      //The following is to reduce the calls to launchAzimuth.
      set azimuth to launchAzimuth(phys_lib["OVatAlt"](Kerbin, orbit_parameters["altitude"]), true).
      print azimuth.
      lock steering to steeringProgram().
   }
   steering_ctl:add("init", init@).

   declare function facing_compass_heading {
      local temp is (-1*ship:bearing).
      if temp < 0 return temp + 360.
      return temp. 
   }

   declare function launchAzimuth {
      parameter OV.
      parameter south.
      local inclination is orbit_parameters["inclination"].

      //It is impossible to launch into an orbit with an inclination < the latitude at the launch site, so if necessary ignore the inclination parameter.
      if abs(ship:latitude) > inclination set inclination to abs(ship:latitude).
      
      local inertialAzimuth is arcsin(cos(inclination)/cos(ship:latitude)).
      //Adjust the IA to a valid compass heading.
      if inertialAzimuth < 0 AND south { //Retrograde South
         set inertialAzimuth to 270-(90-inertialAzimuth).
      } else if inertialAzimuth < 0 { //Retrograde North
         set inertialAzimuth to 360-inertialAzimuth.
      } else if south {
         set inertialAzimuth to 180-inertialAzimuth.
      }
      print "IA: " + inertialAzimuth.
      //Should be the circumference of the cirle of latitude divided by the sidereal rotation period.
      local Vrot is (2*constant:pi*(body:radius+ship:altitude)*cos(ship:latitude))/body:rotationperiod.
      local Vy is OV*cos(inertialAzimuth).
      local Vx is OV*sin(inertialAzimuth)-Vrot.

      local rotatingAzimuth is arctan(Vx/Vy).
      if south return rotatingAzimuth + 180.
      if rotatingAzimuth < 0 return rotatingAzimuth + 360.
      return rotatingAzimuth.
   }

   local progradeVector is ship:srfprograde.
   local inclinationReached is FALSE.
   declare function steeringProgram {
      if ship:altitude < a + 10 {
         return ship:facing.
         //TODO Fix these references to altitude, not robust.  But they fix these cases getting tripped toward the end of ascent.
         //What I need, is some reference to detect the next stage.
      }else if ship:altitude < 10000
               AND (vang(ship:facing:starvector, heading(azimuth, 90):starvector) > 0.5 
               OR ship:airspeed < orbit_parameters["pOverV0"]) {
         return heading(azimuth, 90).
      }else if ship:altitude < 35000 AND ship:airspeed < orbit_parameters["pOverVf"] {
         return heading(azimuth, 90-orbit_parameters["pOverDeg"]).
      }else {
          //Change ProgradeVector
         if ship:altitude >= 35000 {
            print "switch Vector" at(0, 14).
            set progradeVector to ship:prograde.
         } else set progradeVector to ship:srfprograde.
         local progradePitch is 90-vectorangle(up:forevector, progradeVector:forevector).
         print progradePitch at(0, 7).
         //TODO: Fix this, so that headings of 90 or 270 do not give one sided results; for heading of 90, 90-0.01 is a pos inclination, so is 90-0.01.
         //e.g. Am I in midband, or on one side?
         print "Compass: " + facing_compass_heading() at(0, 11).
         if inclinationReached {
            if facing_compass_heading() <= 90 OR facing_compass_heading() >= 270 { //Pointing toward the North.
               if orbit_parameters["inclination"] = 0 {
                  if ship:orbit:inclination < 0.1 return progradeVector.
                  else return progradeVector*R(0, 0.5, 0). // Steer right.
               } else if orbit_parameters["inclination"] = 180 {
                  if ship:orbit:inclination < 180 AND ship:orbit:inclination > 180-0.1 return progradeVector.
                  else return progradeVector*R(0, -0.5, 0). // Steer left.
               } else if ship:orbit:inclination < orbit_parameters["inclination"]-0.01 {
                  return progradeVector*R(0, -1, 0). // Steer left.
               } else if ship:orbit:inclination >= orbit_parameters["inclination"]+0.01 {
                  return progradeVector*R(0, 1, 0). // Steer right.
               } else {
                  return progradeVector.
               }
            } else { //Pointing toward the south.
               if orbit_parameters["inclination"] = 0 {
                  if ship:orbit:inclination < 0.02 return progradeVector.
                  else return progradeVector*R(0, -0.5, 0). // Steer left.
               } else if orbit_parameters["inclination"] = 180 {
                  if ship:orbit:inclination < 180 AND ship:orbit:inclination > 180-0.02 return progradeVector.
                  else return progradeVector*R(0, 0.5, 0). // Steer right.
               } else if ship:orbit:inclination < orbit_parameters["inclination"]-0.01 {
                  return progradeVector*R(0, 1, 0). // Steer right.
               } else if ship:orbit:inclination >= orbit_parameters["inclination"]+0.01 {
                  return progradeVector*R(0, -1, 0). // Steer left.
               } else {
                  return progradeVector.
               }
            }
         } else if ship:orbit:inclination >= orbit_parameters["inclination"]-0.1 AND ship:orbit:inclination <= orbit_parameters["inclination"]+0.1 {
            set inclinationReached to TRUE.
            return progradeVector.
         } else {
            print "Azimuth: "+azimuth at(0, 12).
            print "tgt inc: "+orbit_parameters["inclination"] at(0, 13).
            print "inc: "+ship:orbit:inclination at(0,14).
            return heading(azimuth, progradePitch). 
         }
      }
   }
}
