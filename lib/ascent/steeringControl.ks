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
   local orbit_parameters is lexicon("alt", 80000, "inc", 225, "azWeight", 0.5, "pOverDeg", 4, "pOverV0", 30, "pOverVf", 150).

   local a is 0.
   local azimuth is 0.
   declare function init {
      parameter p.
      if p:istype("Lexicon") {
         set orbit_parameters to p.
      }
      set a to ship:altitude.
      if orbit_parameters["inc"] < abs(ship:geoposition:lat) 
         set orbit_parameters["inc"] to abs(ship:geoposition:lat).
      //The following is to reduce the calls to launchAzimuth.  Also, remember you cannot launch to an inclination less than abs(latitude)
      set azimuth to launchAzimuth(phys_lib["OVatAlt"](Kerbin, orbit_parameters["alt"]), orbit_parameters["inc"]).
      lock steering to steeringProgram().
   }
   steering_ctl:add("init", init@).

   declare function compass_heading {
      local temp is (-1*ship:bearing).
      if temp < 0 return temp + 360.
      return temp. 
   }


   declare function srfRadialVel {
      return (2*constant:pi*(Kerbin:radius)*cos(ship:latitude))/Kerbin:rotationperiod.
   }
   declare function launchAzimuth {
      parameter OV.
      parameter inc.
      parameter south is false.
      
      local inertial is arcsin(cos(inc)/cos(ship:latitude)).
      if inertial < 0 AND south { //Retrograde South
         set inertial to 270-(90-inertial).
      } else if inertial < 0 { //Retrograde North
         set inertial to 360-inertial.
      }
      //Should be the circumference of the cirle of latitude divided by the sidereal rotation period.
      local Vrot is body:rotationperiod/(2*pi()*(body:radius+ship:altitude)*cos(ship:latitude)).
      local Vy is OV*cos(inertial).
      local Vx is OV*sin(inertial)-Vrot.

      local rotAzimuth is atan(Vx/Vy).
      if south return rotAzimuth + 180.
      if rotAzimuth < 0 return rotAzimuth + 360.
   }

   local progradeVector is ship:srfprograde.
   local inclinationReached is FALSE.
   declare function steeringProgram {
      if ship:altitude < a + 10 {
         return ship:facing.
         //TODO Fix these references to altitude, not robust.  But they fix these cases getting tripped toward the end of ascent.
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
         print "Compass: " + compass_heading() at(0, 11).
         if inclinationReached {
            if compass_heading() <= 90 OR compass_heading() >= 270 { //Pointing toward the North.
               if orbit_parameters["inc"] = 0 {
                  if ship:orbit:inclination < 0.1 return progradeVector.
                  else return progradeVector*R(0, 0.5, 0). // Steer right.
               } else if orbit_parameters["inc"] = 180 {
                  if ship:orbit:inclination < 180 AND ship:orbit:inclination > 180-0.1 return progradeVector.
                  else return progradeVector*R(0, -0.5, 0). // Steer left.
               } else if ship:orbit:inclination < orbit_parameters["inc"]-0.01 {
                  return progradeVector*R(0, -1, 0). // Steer left.
               } else if ship:orbit:inclination >= orbit_parameters["inc"]+0.01 {
                  return progradeVector*R(0, 1, 0). // Steer right.
               } else {
                  return progradeVector.
               }
            } else { //Pointing toward the south.
               if orbit_parameters["inc"] = 0 {
                  if ship:orbit:inclination < 0.02 return progradeVector.
                  else return progradeVector*R(0, -0.5, 0). // Steer left.
               } else if orbit_parameters["inc"] = 180 {
                  if ship:orbit:inclination < 180 AND ship:orbit:inclination > 180-0.02 return progradeVector.
                  else return progradeVector*R(0, 0.5, 0). // Steer right.
               } else if ship:orbit:inclination < orbit_parameters["inc"]-0.01 {
                  return progradeVector*R(0, 1, 0). // Steer right.
               } else if ship:orbit:inclination >= orbit_parameters["inc"]+0.01 {
                  return progradeVector*R(0, -1, 0). // Steer left.
               } else {
                  return progradeVector.
               }
            }
         } else if ship:orbit:inclination >= orbit_parameters["inc"]-0.1 AND ship:orbit:inclination <= orbit_parameters["inc"]+0.1 {
            set inclinationReached to TRUE.
            return progradeVector.
         } else {
            print "Azimuth: "+azimuth at(0, 12).
            print "tgt inc: "+orbit_parameters["inc"] at(0, 13).
            return heading(azimuth, progradePitch). 
         }
      }
   }
}
