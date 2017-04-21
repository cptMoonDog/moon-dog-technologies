@LAZYGLOBAL OFF.
///////////////User Functions
declare function RestrictRange {
   parameter mx.
   parameter mn.
   parameter val.
   if val > mx return mx.
   if val < mn return mn.
   return val.
}.