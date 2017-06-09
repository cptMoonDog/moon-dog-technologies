clearscreen.
until false {
   //Longitude correction of launch window due to latitude.
   set lonOffset to arcsin(tan(ship:latitude)/tan(target:orbit:inclination)).
   
   set astroLon to normalizeAngle((kerbin:rotationangle+ship:longitude)).
   set degFromAN to normalizeAngle(astroLon - target:orbit:LAN).
   set degToDN to normalizeAngle((180-degFromAN)-lonOffset).
   set degToAN to normalizeAngle((360-degFromAN)+lonOffset).
   print "Offset: "+lonOffset at(0,3).
   print "deg to AN Launch point (head north): "+(degToAN) at(0, 5).
   print "T-"+(Kerbin:rotationperiod/360)*degToAN at(0,6).
   print "deg to DN Launch point (head south): "+(degToDN) at(0, 7).
   print "T-"+(Kerbin:rotationperiod/360)*degToDN at(0,8).
   wait 0.01.
}
declare function normalizeAngle {
   parameter theta.
   if theta < 0 return theta + 360.
   else return theta.
}

declare function countdown_to_window {
   parameter RAAN.
   parameter i.
   parameter allowable is "all". 

   //Longitude correction of launch window due to latitude.
   set lonOffset to arcsin(tan(ship:latitude)/tan(i)).
   set astroLon to normalizeAngle((kerbin:rotationangle+ship:longitude)).
   set degFromAN to normalizeAngle(astroLon - target:orbit:LAN).
   set degToDN to normalizeAngle((180-degFromAN)-lonOffset).
   set degToAN to normalizeAngle((360-degFromAN)+lonOffset).

   if allowable = "all" {
      if degToDN < degToAN {
         return (Kerbin:rotationperiod/360)*degToDN.
      } else {
         return (Kerbin:rotationperiod/360)*degToAN.
      }
   } else if allowable = "north" {
      return (Kerbin:rotationperiod/360)*degToAN.
   } else {
      return (Kerbin:rotationperiod/360)*degToDN.
   }

}

 
