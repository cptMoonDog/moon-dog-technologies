//SteeringControl.ks
//Handles steering during rocket ascent.
//James McConnel
// TODO allow steering to fix inclination after locking to prograde.  Currently does not adjust when it overshoots.
//FYI's :
// Orbital inclination is never reported in practice as more that 180.  
// Launching South then, is in practice indistinguishable from launching North, at least orbit wise.
// However, this script will accept larger "inclinations" in order to support launching South.
//
//Mon Jun 19 21:16:05 PDT 2017
@LAZYGLOBAL off.
{
   parameter p.
   parameter a.
  
   runoncepath("general.ks").
 
   //Library's exportable functions
   if not defined ascent_ctl 
      global ascent_ctl is lexicon().

   //Local variables
   local orbit_parameters is lexicon("altitude", 80000, "inclination", 90).
   local ascent_parameters is lexicon("hemisphere", "north", "pOverDeg", 4, "pOverV0", 30, "pOverVf", 150).

   local h0 is 0.
   local azimuth is 0.
   local progradeVector is ship:srfprograde.
   local inclinationReached is FALSE.

   if p:istype("Lexicon") {
      set orbit_parameters to p.
   }
   if a:istype("Lexicon") {
      set ascent_parameters to a.
   }
   set h0 to ship:altitude.
   //The following is to reduce the calls to launchAzimuth.
   set azimuth to launchAzimuth().

   //Init
   //declare function init {
      //parameter p.
      //parameter a.
      //if p:istype("Lexicon") {
         //set orbit_parameters to p.
      //}
      //if a:istype("Lexicon") {
         //set ascent_parameters to a.
      //}
      //set h0 to ship:altitude.
      ////The following is to reduce the calls to launchAzimuth.
      //set azimuth to launchAzimuth().
   //}
   //ascent_ctl:add("init", init@).


///Public functions
   declare function steeringProgram {
      //Prior to clearing the tower
      if ship:altitude < h0 + 10 {
         return ship:facing.
         //TODO Fix these references to altitude, not robust.  But they fix these cases getting tripped toward the end of ascent.
         //What I need, is some reference to detect the next stage.
      //Roll to Azimuth
      }else if ship:airspeed < ascent_parameters["pOverV0"] AND vang(ship:facing:starvector, heading(azimuth, 90):starvector) > 0.5 AND ship:apoapsis < 35000 {
         return heading(azimuth, 90).
      //Pitchover
      }else if ship:apoapsis < 35000 AND ship:airspeed < ascent_parameters["pOverVf"] {
         return heading(azimuth, 90-ascent_parameters["pOverDeg"]).
      }else {
          //Change ProgradeVector
         if ship:altitude >= 35000 {
            set progradeVector to ship:prograde.
         } else set progradeVector to ship:srfprograde.
         local progradePitch is 90-vectorangle(up:forevector, progradeVector:forevector).
         print progradePitch at(0, 7).
         print "Compass: " + facing_compass_heading() at(0, 11).
         print orbit_parameters["inclination"] at(0,14).
         if inclinationReached {
            return progradeVector.
         } else if ship:orbit:inclination >= orbit_parameters["inclination"]-0.001 {
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
   ascent_ctl:add("steering_monitor", steeringProgram@).
   
///Private functions
   declare function facing_compass_heading {
      local temp is (-1*ship:bearing).
      if temp < 0 return temp + 360.
      return temp. 
   }

   declare function launchAzimuth {
      local OV is phys_lib["OVatAlt"](Kerbin, 70000).//orbit_parameters["altitude"]).
      local south is false.
      if ascent_parameters["hemisphere"] = "south" set south to true.

      //It is impossible to launch into an orbit with an inclination < the latitude at the launch site, so if necessary ignore the inclination parameter.
      //Therefore acceptable inclinations are >= abs(latitude) and =< 180-abs(latitude).
      //TODO Maybe not a good idea clobbering an input value, but on the other hand, this value will need to be corrected program wide.
      //Would it be better to throw an error and force user intelligence?
      if abs(ship:latitude) > orbit_parameters["inclination"] set orbit_parameters["inclination"] to abs(ship:latitude).
      else if abs(ship:latitude)+orbit_parameters["inclination"]  > 180 set orbit_parameters["inclination"] to 180-abs(ship:latitude).
      
      local inertialAzimuth is arcsin(cos(orbit_parameters["inclination"])/cos(ship:latitude)).

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
      print "IA: "+inertialAzimuth.

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
}
