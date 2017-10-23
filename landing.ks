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
   } else if ship:verticalspeed < 0 return ship:srfretrograde.
   else return geo_normalvector(ship:geoposition, 1).
}

declare function burn_length {
   parameter dv.
   //return (ship:mass/60)*dv.
   local m2 is ship:mass*1000*constant:e^(-dV/(345*9.80665)).
   return ((ship:mass*1000-m2)/(17.734195)).
}
declare function quadraticFormula {
   parameter a, b, c.
   local result is list(-b, -b).
   local underRadical is b^2 - 4*a*c.
   if underRadical < 0 set underRadical to 0. //No, I'm not handling Complex numbers right now.  Thank you for asking.
   set result[0] to result[0] + sqrt(underRadical).
   set result[1] to result[1] - sqrt(underRadical).
   set result[0] to result[0]/(2*a).
   set result[1] to result[1]/(2*a).
   return result.
}
declare function timeToImpact_parabolic {
   // Quadratic formula used with the kinematic equations, solving for time
   //                      a is (1/2)g                                            b is V0 vertical         c is -distance (neg, b/c set equation set equal to 0).
   //                      |                                                      |                        |
   //                      \/                                                     \/                       \/         
   return quadraticFormula((ship:body:mu/((ship:altitude+ship:body:radius)^2))/2, abs(ship:verticalspeed), -(ship:altitude-ship:geoposition:terrainheight))[0].
}
declare function distanceToImpact_parabolic {
   return ship:groundspeed*timeToImpact_parabolic().
}
declare function betterTimeToImpact {
   local start is timeToImpact_parabolic().
   local pos is positionat(ship, time:seconds+start).
   local impactPointTerrainHeight is ship:body:geopositionof(pos):terrainheight.
   local altitudeAtStart is ship:body:altitudeof(pos).
   local step is 100.
   until altitudeAtStart - impactPointTerrainHeight < 1 and altitudeAtStart - impactPointTerrainHeight > 0 {
      set start to start + step.
      set pos to positionat(ship, time:seconds+start).
      set impactPointTerrainHeight to ship:body:geopositionof(pos):terrainheight.
      set altitudeAtStart to ship:body:altitudeof(pos).
      if altitudeAtStart - impactPointTerrainHeight < 0 {
         if step < 1 return start - step.
         set start to start - step.
         set step to step/10.
         set pos to positionat(ship, time:seconds+start).
         set impactPointTerrainHeight to ship:body:geopositionof(pos):terrainheight.
         set altitudeAtStart to ship:body:altitudeof(pos).
      }
   }
}

declare function TTI_adjustedTerrainAtImpact {
   local currentAltAboveImpactPointTerrain is ship:altitude - ship:orbit:body:geopositionof(positionat(ship, time:seconds+timeToImpact_parabolic())):terrainheight.
   return quadraticFormula(ship:body:mu/(2*(ship:altitude+ship:body:radius)), abs(ship:verticalspeed), -currentAltAboveImpactPointTerrain)[0].
}
declare function distanceToImpact_adjusted {
   return ship:groundspeed*TTI_adjustedTerrainAtImpact().
}
lock steering to getDirection().
lock throttle to 0.
until vang(ship:facing:forevector, ship:retrograde:forevector) < 0.5 {
   print vang(ship:facing:forevector, ship:retrograde:forevector) at(0, 4).
}
until ship:periapsis < 0 lock throttle to 1.
lock throttle to 0.
gear on.

set P to PIDLOOP().
set P:maxOutput to 1.
set P:minOutput to 0.
set h to shipHeight().

set corePosition to 0. //Distance from top of ship to center of KOS module.
local calcStart is time:seconds.
local accurateTAI is time:seconds + betterTimeToImpact().
local calcEnd is time:seconds.
local tti is accurateTAI-time:seconds.
local vAtImpact is velocityAt(ship, time:seconds+tti):surface:mag.
local groundDistToImpact is ship:groundspeed*tti.
until alt:radar < h-corePosition {
   set tti to accurateTAI-time:seconds.
   if ship:verticalspeed < 0 {
      if ship:altitude < ship:body:geopositionof(positionat(ship, time:seconds+tti)):terrainheight or 
         vang(geo_normalvector(ship:body:geopositionof(positionat(ship, time:seconds+tti)), 10000), geo_normalvector(ship:body:geopositionof(positionat(ship, time:seconds+tti)), 1)) > 15 {
         print "adjusting for Terrain" at(0, 1).
         lock throttle to 1.
      } else if groundDistToImpact < (2*ship:body:radius*constant:pi)/64 {
         print "current Mode: parabolic" at(0, 1).
         set tti to timeToImpact_parabolic().
         if ship:groundspeed > 10 set vAtImpact to velocityAt(ship, time:seconds+tti):surface:mag.
         else set vAtImpact to abs(ship:verticalspeed)+((ship:body:mu)/((ship:altitude+ship:body:radius)^2))*tti.
      } else if accurateTAI - burn_length(velocityAt(ship, accurateTAI):surface:mag) - 10 < time:seconds {
         print "current Mode: elliptical" at(0, 1).
         local last is time:seconds.
         if accurateTAI > 0 set last to accurateTAI.
         set calcStart to time:seconds.
         set accurateTAI to time:seconds + betterTimeToImpact().
         set calcEnd to time:seconds.
         if accurateTAI < 0 {
            set accurateTAI to last.
         }
         set tti to accurateTAI - time:seconds.
         set vAtImpact to velocityAt(ship, time:seconds+tti):surface:mag.
      } else if accurateTAI - burn_length(velocityAt(ship, accurateTAI):surface:mag) > time:seconds + 280 {
         lock throttle to 0.
         if kuniverse:timewarp:warp = 0 and kuniverse:timewarp:rate = 1 and Kuniverse:timewarp:issettled() {
            kuniverse:timewarp:warpto(accurateTAI - burn_length(velocityAt(ship, accurateTAI):surface:mag) - 279).
         } else until vang(ship:facing:forevector, ship:retrograde:forevector) < 0.5 {
            print vang(ship:facing:forevector, ship:retrograde:forevector) at(0, 17).
         }
      }
      lock throttle to p:update(time:seconds, max(0, tti)).
      set p:setpoint to burn_length(vAtImpact).
      set groundDistToImpact to ship:groundspeed*tti.
   } else lock throttle to 0.
   print "Time To Impact (pvar): " + max(0, tti) at(0, 2).
   print "burn length (sp): " + burn_length(velocityAt(ship, time:seconds+tti):surface:mag) at(0, 3).
   print "Vel at impact: "+ velocityat(ship, tti):surface:mag at(0, 7).
   print "Alt at Impact: " + ship:orbit:body:geopositionof(positionat(ship, tti)):terrainheight at(0, 9).
   print "Calculation time: " + (calcEnd - calcStart) at(0, 11).
   print "x dist to impact: " + groundDistToImpact at(0, 12).
   print "Body Circum.: " + (2*ship:body:radius*constant:pi) at(0, 13).
   print "mode change x dist: " + (2*ship:body:radius*constant:pi)/64 at(0, 14).
   print "warp time: " + (accurateTAI - time:seconds - burn_length(velocityAt(ship, accurateTAI):surface:mag) - 180) at(0, 16).
}
lock throttle to 0.
lock steering to geo_normalvector(ship:geoposition, 1).
print "holding slope normal".
wait 60.
print "done.".
