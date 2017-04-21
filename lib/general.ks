@LAZYGLOBAL off.
{
   global phys_lib is lexicon().
   declare function OVatAlt {
      parameter bod is Kerbin.
      parameter alt is 0.
      return sqrt(bod:mu/(bod:radius + alt)).  
   }
   phys_lib:add("OVatAlt", OVatAlt@).

   declare function VatAlt {
      parameter bod is Kerbin.
      parameter alt is 0.
      return sqrt(bod:mu*(2/(alt + bod:radius) - 1/(ship:orbit:semimajoraxis))).
   }
   phys_lib:add("VatAlt", VatAlt@).
   local g0 to 9.80665. //m/s^2
   phys_lib:add("g0", g0).

}
