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
      if h < 90 return (90 - h) + ":N".
      if h > 90 and h < 270 {
         return (h-90) + ":S".
      }
      if h > 270 return (450 - h) + ":N".
   }


   declare function launchAzimuth {
      parameter OV.
      parameter inc.
      // OV is the velocity which, once attained, will have the rocket in the correct inclination.
      // Rotational velocity is subtracted, because that amount of velocity is already there.
      local Vx is (orbit_parameters["azWeight"]*OV)*sin(inc_to_heading(inc))-174.97. //174.97: Rotational Velocity of Kerbin at equator.
      local Vy is (orbit_parameters["azWeight"]*OV)*cos(inc_to_heading(inc)).

      print "Vx: "+Vx at(0, 15).
      print "Vy: "+Vy at(0, 16).
      print "inc: "+ship:orbit:inclination at(0, 17).
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
         //Am I in midband, or on one side?
         if inclinationReached {
            if ship:orbit:inclination <= orbit_parameters["inc"]-0.05 {
               return progradeVector*R(0,-1,0).
            } else if ship:orbit:inclination >= orbit_parameters["inc"]+0.05 {
               return progradeVector*R(0, 1, 0).
            } else {
               return progradeVector.
            }
         } else if ship:orbit:inclination >= orbit_parameters["inc"]-0.1 AND ship:orbit:inclination <= orbit_parameters["inc"]+0.1 {
            set inclinationReached to TRUE.
            print "progradeVector" at(0, 12).
            return progradeVector.
         } else {
            print "Azimuth: "+azimuth at(0, 12).
            print "tgt inc: "+orbit_parameters["inc"] at(0, 13).
            return heading(azimuth, progradePitch). 
         }
      }
   }
}
