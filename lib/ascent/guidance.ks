
   declare function init_guidance {
      parameter launchTo is "window".
      parameter orbit_parameters is lexicon().
      parameter pitch_parameters is lexicon().
      parameter throttle_profile is list().
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
      
      local inertialAzimuth is arcsin(min(1, cos(inclination)/cos(ship:latitude))). //min function prevents occasional NAN.

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

