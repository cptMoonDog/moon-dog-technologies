@LAZYGLOBAL off.
{
   global phys_lib is lexicon().

   declare function facing_compass_heading {
      local temp is (-1*ship:bearing).
      if temp < 0 return temp + 360.
      return temp. 
   }
   declare function visViva_altitude {
      parameter bod.
      parameter vel.
      parameter sma.

      return 2/(((vel^2)/bod:mu)+1/sma)-bod:radius.
   }

}
   global g0 is 9.80665.
   
   declare function semimajoraxis {
      parameter bod.
      parameter alt1.
      parameter alt2.
      return ((alt2+bod:radius)+(alt1+bod:radius))/2.
   }

   //Returns the velocity of an object at alt in an orbit with a Semi major axis of sma.
   //For instance: for a ship in a circular 80k orbit wishing to transfer to Minmus 46400k altitude,
   //would require a visViva_velocity(body("Kerbin"), 80000, smaOfTransferOrbit(body("Kerbin"), 80000, body("Minmus"):orbit:altitude)-ship:orbit:velocity
   //increase in velocity.
   declare function visViva_velocity {
      parameter bod.
      parameter alt.
      parameter sma.
      return sqrt(bod:mu*(2/(bod:radius+alt)-1/sma)).  
   }
   phys_lib:add("VatAlt", visViva_velocity@).

   declare function OVatAlt {
      parameter bod is Kerbin.
      parameter alt is 0.
      return visViva_velocity(bod, alt, bod:radius+alt).
   }
   phys_lib:add("OVatAlt", OVatAlt@).
