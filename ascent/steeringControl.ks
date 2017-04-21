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

   run general.ks.

   global steering_ctl is lexicon().
   local orbit_parameters is lexicon("alt", 80000, "inc", 225, "pOverDeg", 4, "pOverV0", 30, "pOverVf", 150).

   declare function init {
      parameter p.
      set orbit_parameters to p.
      lock steering to steeringProgram().
   }
   steering_ctl:add("init", init@).

   declare function inc_to_heading {
      declare parameter i is 90.
      if i <= 90 
         return 90 - i.
      if i > 90  
         return 90 - i + 360.
   }

   declare function launchAzimuth {
      parameter OV.
      parameter inc.
      local Vx is (0.75*OV)*sin(inc_to_heading(inc))-174.97. //174.97: Rotational Velocity of Kerbin.
      local Vy is (0.75*OV)*cos(inc_to_heading(inc)).

      print "Vx: "+Vx at(0, 15).
      print "Vy: "+Vy at(0, 16).
      print "inc: "+ship:orbit:inclination at(0, 17).
      if Vy = 0 if Vx < 0 return 270. else return 90.
      if Vx = 0 if Vy < 0 return 180. else return 0.
      if Vy < 0 return arctan(Vx/Vy)+180.
      else return arctan(Vx/Vy).
   }

   //Due to the way inclination is reported, this will return a value between 0 and 180.
   declare function heading_to_inclination {
      declare parameter h is 0.
      if h <= 270 return abs(90 - h).
      else return 90 - h + 360.
   }

   local a to ship:altitude.
   declare function steeringProgram {
      if ship:altitude < a + 10 {
         return ship:facing.
         //TODO Fix these references to altitude, not robust.  But they fix these cases getting tripped toward the end of ascent.
      }else if ship:altitude < 10000 AND (vang(ship:facing:starvector, heading(launchAzimuth(phys_lib["OVatAlt"](Kerbin, orbit_parameters["alt"]), orbit_parameters["inc"]), 90):starvector) > 0.5 OR ship:airspeed < orbit_parameters["pOverV0"]) {
         return heading(launchAzimuth(phys_lib["OVatAlt"](Kerbin, orbit_parameters["alt"]), orbit_parameters["inc"]), 90).
      }else if ship:altitude < 35000 AND ship:airspeed < orbit_parameters["pOverVf"] {
         return heading(launchAzimuth(phys_lib["OVatAlt"](Kerbin, orbit_parameters["alt"]), orbit_parameters["inc"]), 90-orbit_parameters["pOverDeg"]).
      }else {
         local progradeVector is ship:srfprograde.
         local progradePitch is 90-vectorangle(up:forevector, progradeVector:forevector).
          //Change ProgradeVector
         if ship:altitude >= 35000 {
            print "switch Vector" at(0, 14).
            set progradeVector to ship:prograde.
         }
         print progradePitch at(0, 7).
         if ship:orbit:inclination >= heading_to_inclination(orbit_parameters["inc"]-0.1) AND ship:orbit:inclination <= heading_to_inclination(orbit_parameters["inc"]+0.1) {
            print "progradeVector" at(0, 12).
            return progradeVector.
         } else if ship:orbit:inclination >= heading_to_inclination(orbit_parameters["inc"]) {
            print "adjust           " at(0, 12).
            return heading(inc_to_heading(orbit_parameters["inc"]+1), progradePitch).
         }
           else {
            print "Azimuth: "+launchAzimuth(phys_lib["OVatAlt"](Kerbin, orbit_parameters["alt"]), orbit_parameters["inc"]) at(0, 12).
            print "tgt inc: "+heading_to_inclination(orbit_parameters["inc"]) at(0, 13).
            return heading(launchAzimuth(phys_lib["OVatAlt"](Kerbin, orbit_parameters["alt"]), orbit_parameters["inc"]), progradePitch). 
         }
      }
   }
}
