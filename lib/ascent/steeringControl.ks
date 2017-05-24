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
      set azimuth to launchAzimuth(phys_lib["OVatAlt"](Kerbin, orbit_parameters["alt"]), orbit_parameters["inc"]).
      lock steering to steeringProgram().
   }
   steering_ctl:add("init", init@).

   //The purpose of this function is to adjust for the 90 degree difference between inclination and heading angles
   //for inclinations < 180.
   declare function inc_to_heading {
      declare parameter i.
      declare parameter hemisphere is "NORTH".
      if i < 0 or i > 180 
         return "INDEX OUT OF RANGE: NOT AN INCLINATION".
      if hemisphere:toupper = "NORTH" {
         if i <= 90 
            return 90 - i.
         if i > 90  
            return 90 - i + 360.
      }
       if hemisphere:toupper = "SOUTH" {
         return 90 + i.
      }
  }
   //Due to certain properties of inclination this will return a value between 0 and 180.
   declare function heading_to_inclination {
      declare parameter h.
      if h < 0 or h > 360 return "INDEX OUT OF RANGE: NOT A HEADING".
      if h <= 90 return (90 - h) + ":N".
      if h > 90 and h < 270 {
         return (h-90) + ":S".
      }
      if h > 270 return (450 - h) + ":N".
   }
   declare function compass_heading {
      //local Npole is latlng(90, 0).
      local temp is (-1*ship:bearing).
      if temp < 0 return temp + 360.
      return temp. //360-Npole:bearing.
   }


   declare function launchAzimuth {
      parameter OV.
      parameter inc.
      // OV is the velocity which, once attained, will have the rocket in the correct inclination.
      // Rotational velocity is subtracted, because that amount of velocity is already there.
      local xtemp is sin(inc_to_heading(inc)).
      if xtemp < 0.000001 set xtemp to 0.
      local ytemp is cos(inc_to_heading(inc)).
      if ytemp < 0.000001 set ytemp to 0.
      local Vx is (orbit_parameters["azWeight"]*OV)*xtemp-174.97. //174.97: Rotational Velocity of Kerbin at equator.
      local Vy is (orbit_parameters["azWeight"]*OV)*ytemp.

      //Avoid div by zero error
      if Vy = 0 
         if Vx < 0 return 270.
         else return 90.
      if Vx < 0 or Vy < 0 return arctan(Vx/Vy)+360.
      else return arctan(Vx/Vy).
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
