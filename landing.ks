runpath("0:/lib/general.ks").
clearscreen.
declare function shipHeight {
   //Taken from: https://www.reddit.com/r/Kos/comments/33myzd/adventures_in_determining_the_height_of_crafts/
   list parts in partList.
   lock r3 to facing:forevector.
   set highestPart to 0.
   set lowestPart to 0.
   for part in partList{
       set v to part:position.
       set currentPart to vdot(r3, v)..
       if currentPart > highestPart
           set highestPart to currentPart.
       else if currentPart < lowestPart
           set lowestPart to currentPart.
   }
   set height to highestPart - lowestPart.
   return height.
}
declare function getAltitude {
   if ship:altitude > 10000 return ship:altitude.
   return alt:radar.
}
declare function relativeApo {
   if ship:altitude > 6000 return ship:apoapsis.
   return (ship:apoapsis-(ship:altitude-alt:radar)).
}
// From: https://www.reddit.com/r/Kos/comments/3ai4uu/planet_surface_related_functions_library_resource/
// parameter 1: a geoposition ( ship:GEOPOSITION / body:GEOPOSITIONOF(position) / LATLNG(latitude,longitude) )
// parameter 2: size/"radius" of the triangle. Small number gives a local normalvector while a larger one will tend to give a more average normalvector.
// returns: Normalvector of the terrain. (Can be used to determine the slope of the terrain.)
function geo_normalvector {
        parameter geopos,size_.
        set size to max(5,size_).
        local center is geopos:position.
        local fwd is vxcl(center-body:position,body:angularvel):normalized.
        local right is vcrs(fwd,center-body:position):normalized.
        local p1 is body:geopositionof(center + fwd * size_ + right * size_).
        local p2 is body:geopositionof(center + fwd * size_ - right * size_).
        local p3 is body:geopositionof(center - fwd * size_).
       
        local vec1 is p1:position-p3:position.
        local vec2 is p2:position-p3:position.
        local normalVec is vcrs(vec1,vec2):normalized.
       
        //debug vecdraw: local markNormal is vecs_add(center,normalVec * 300,rgb(1,0,1),"slope: " + round(vang(center-body:position,normalVec),1) ).
 
        return normalVec.
}
declare function getDirection {
   if ship:altitude > 50000 return ship:retrograde.
   else if getAltitude() < 50000 and ship:verticalspeed < -1*(ship:apoapsis/ship:groundspeed) {
      return ship:srfretrograde:forevector+angleaxis(-(vang(up:forevector, ship:srfretrograde:forevector)*(min(1, ship:groundspeed/getAltitude()))), ship:srfretrograde:starvector).
   } else return ship:srfretrograde.
}
lock steering to getDirection().
local thrott is 0.
lock throttle to thrott.
until vang(ship:facing:forevector, ship:retrograde:forevector) < 0.5 {
   print vang(ship:facing:forevector, ship:retrograde:forevector) at(0, 4).
}

   ///////Functions for calculating a better non-impulsive maneuver.
   //mass after first half of burn
   declare function m2 {
      parameter dv.
      return ship:mass*1000*(constant:e^(-((dV/2)/(345*9.80665)))).
   }
   declare function burn_length_first_half {
      parameter dv.
      return ((ship:mass*1000-m2(dv))/(17.734195)).
   }
   declare function burn_length_second_half {
      parameter dv.
      local m3 is m2(dv)/(constant:e^((dV/2)/(345*9.80665))).
      return ((m2(dv)-m3)/(17.734195)).
   }
set P to PIDLOOP().
set P:maxOutput to 1.
set P:minOutput to 0.
set h to shipHeight().

set corePosition to 0. //Distance from top of ship to center of KOS module.
set SBLength to 120.
local vspeed is ship:verticalspeed.
until getAltitude() < h-corePosition {
   local timeToImpact is (-abs(ship:verticalspeed) + sqrt(ship:verticalspeed^2 + 2*(ship:orbit:body:mu/((getAltitude()+ship:orbit:body:radius)^2))*getAltitude()))/(ship:orbit:body:mu/((getAltitude()+ship:orbit:body:radius)^2)).
   local distImpact is ship:groundspeed*timeToImpact.
   local pctError is distImpact/(constant:pi*2*ship:orbit:body:radius).
   local VertVatT is ship:verticalspeed - ((ship:orbit:body:mu/((getAltitude()+ship:orbit:body:radius)^2)))*timeToImpact.
   local VatImpact is sqrt((VertVatT)^2 + ship:groundspeed^2).
   
   local adjustedTTI is timeToImpact*(1+pctError).
   local adjustedDist is distImpact*(1+pctError).

   print "Time To Impact (est): "+adjustedTTI at(0, 4).
   print "Horizontal distance to impact: "+ adjustedDist at(0, 5).
   print "%Error: "+ pctError at(0, 6).
   print "Vert Speed at impact (est): "+ VertVatT at(0, 7).
   print "Vel at impact: "+ VatImpact at(0, 8).
   print "burn length: " + (burn_length_first_half(VatImpact) + burn_length_second_half(VatImpact)) at(0, 9).
   set p:setpoint to (burn_length_first_half(VatImpact) + burn_length_second_half(VatImpact)).
   lock throttle to p:update(time:seconds, adjustedTTI).

//   if eta:periapsis < eta:apoapsis and vang(up:forevector, ship:facing:forevector) > 89 and vang(up:forevector, ship:facing:forevector) < 91 {
//      set thrott to 1.
//   } else if thrott = 1 and ship:periapsis > 0 {
//      set thrott to 1.
//   } else if visViva_Velocity(Mun, 0, (ship:apoapsis+Mun:radius+Mun:radius+ship:periapsis)/2) > 
//   if ship:velocity:orbit:mag > OVatAlt(Mun, ship:altitude) and ship:altitude < 20000 {
//      set thrott to 1.
//   } else if ship:periapsis > 5000 { //Deorbit
//      set thrott to 1.
//   } else if ship:verticalspeed > -5 {
//      set thrott to 0.
//   } else if getAltitude() < 20000 {
//      set thrott to min(1, abs((ship:groundspeed+getAltitude()/1000)/ship:verticalspeed)).
//      if ship:verticalspeed < vspeed set thrott to thrott*2.
//   } else set thrott to 0.

   //   if ship:periapsis > 100 or (getAltitude() < 500 and ship:velocity:surface:mag < 10)
//      set thrott to 1-getAltitude()/relativeApo(). //or getAltitude() < 6000 
//   else if getAltitude() < 1000 and ship:verticalspeed < -5 set thrott to 1. //(getAltitude()/abs(ship:verticalspeed)) < SBLength 
//   else set thrott to 0.
}
lock throttle to 0.
lock steering to geo_normalvector(ship:geoposition, 1).
print "holding slope normal".
wait 10.
print "done.".
