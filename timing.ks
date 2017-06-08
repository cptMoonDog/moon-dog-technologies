clearscreen.
until false {
   set lonOffset to arcsin(tan(ship:latitude)/tan(target:orbit:inclination)).
   set astroLon to (kerbin:rotationangle+ship:longitude).
   if astroLon < 0 set astroLon to astroLon + 360.
   set diff to astroLon - target:orbit:LAN.
   if diff < 0 set diff to diff + 360.
   set degToAN to 360-diff.
   print "offset: "+lonOffset at(0,3).
   print "deg to AN: "+(degToAN+lonOffset) at(0, 4).
   print "T-"+(Kerbin:rotationperiod/360)*degToAN at(0,5).
   wait 1.
}

