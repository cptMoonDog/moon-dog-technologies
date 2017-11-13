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
   //                      a is (1/2)g                                            b is V0 vertical         c is -distance (neg, b/c equation set equal to 0).
   //                      |                                                      |                        |
   //                      \/                                                     \/                       \/         
   return quadraticFormula((ship:body:mu/((ship:altitude+ship:body:radius)^2))/2, abs(ship:verticalspeed), -(ship:altitude-ship:geoposition:terrainheight))[0].
}
declare function distanceToImpact_parabolic {
   return ship:groundspeed*timeToImpact_parabolic().
}
local calcStart is time:seconds.
local calcEnd is time:seconds.
declare function ellipticalimpactTime_ut {
   set calcStart to time:seconds.
   local utImpact_est is time:seconds+eta:periapsis.
   local pos is positionat(ship, utImpact_est).
   local terrainAtPos is ship:body:geopositionof(pos):terrainheight.
   if ship:periapsis < terrainAtPos { 
      set utImpact_est to (eta:periapsis-timeToImpact_parabolic())/2 + timeToImpact_parabolic()+time:seconds.
      set pos to positionat(ship, utImpact_est).
      set terrainAtPos to ship:body:geopositionof(pos):terrainheight.
   } else {
      clearvecdraws().
      vecdraw(v(0,0,0), pos, red, "", 1.0, true, 0.2).
      set calcEnd to time:seconds.
      return time:seconds+eta:periapsis.
   }
   local altitudeAtPos is ship:body:altitudeof(pos).
   local step is 100.
   until altitudeAtPos - terrainAtPos < 1 and altitudeAtPos - terrainAtPos > 0 {
      if altitudeAtPos - terrainAtPos < 0 or utImpact_est-time:seconds > eta:periapsis {
         set utImpact_est to utImpact_est - 2*step.
         set step to step/10.
      } else {
         set utImpact_est to utImpact_est + step.
      }
      set pos to positionat(ship, utImpact_est).
      set terrainAtPos to ship:body:geopositionof(pos):terrainheight.
      set altitudeAtPos to ship:body:altitudeof(pos).
   }
   clearvecdraws().
   vecdraw(v(0,0,0), pos, yellow, "", 1.0, true, 0.2).
   set calcEnd to time:seconds.
   return utImpact_est - step.
}

declare function TTI_adjustedTerrainAtImpact {
   //local currentAltAboveImpactPointTerrain is ship:altitude - ship:orbit:body:geopositionof(positionat(ship, time:seconds+timeToImpact_parabolic())):terrainheight.
   return quadraticFormula((ship:body:mu/((ship:altitude+ship:body:radius)^2))/2, abs(ship:verticalspeed), -alt:radar)[0]-5.
}
declare function distanceToImpact_adjusted {
   return ship:groundspeed*TTI_adjustedTerrainAtImpact().
}

//Steering and throttle
declare function steeringFunction {
   if ship:periapsis > 0 return ship:retrograde:forevector.
   else {
      return ship:srfretrograde:forevector.
   }
}
local runmode is 0.

local P is PIDLOOP().
set P:maxOutput to 1.
set P:minOutput to 0.
local accurateTAI is ellipticalimpactTime_ut().
local tti is accurateTAI-time:seconds.
local vAtImpact is velocityAt(ship, time:seconds+tti):surface:mag.
local groundDistToImpact is ship:groundspeed*tti.
local minSafeAltitude is 8000.
local thrott is 0.
local lastTTB is eta:periapsis.
declare function throttleFunction {
   lock steering to ship:srfretrograde.
   set vAtImpact to velocityAt(ship, time:seconds+eta:periapsis):surface:mag.
   local bl is burn_length(vAtImpact).
   if ship:velocity:surface:mag < 3 lock throttle to 0.
   else if eta:periapsis < 10 lock throttle to max(0, min(1, (thrott + (bl-TTI_adjustedTerrainAtImpact())/max(0.00001, TTI_adjustedTerrainAtImpact())))).
   else if ship:periapsis < 0 lock throttle to max(0, min(1, (thrott + (bl-TTI_adjustedTerrainAtImpact())/max(0.00001, TTI_adjustedTerrainAtImpact())))).

   //else lock throttle to 0.
   //print "tti elliptical: "+ (ellipticalimpactTime_ut()-time:seconds) at(0, 1).
   print "tti parabolic: " + TTI_adjustedTerrainAtImpact() at(0, 2).
   print "burn length: "+ bl at(0, 3).
   print "time to burn: "+eta:periapsis at(0, 4).
   //set thrott to max(0, min(1, (thrott + (bl-(timetoburn-20))/max(0.00001, timetoburn)))).
   //lock throttle to thrott.
}

//Begin 
set h to shipHeight().

set corePosition to 0. //Distance from top of ship to center of KOS module.
until runmode > 4 {
   if runmode = 0 { //Deorbit
      lock steering to ship:retrograde.
      if ship:verticalspeed < 0 or eta:apoapsis < 10 {
         if vang(ship:facing:forevector, ship:retrograde:forevector) < 0.5 and ship:periapsis > minSafeAltitude {
            lock throttle to 1.
         } else if ship:periapsis < minSafeAltitude {
            lock throttle to 0.
            set accurateTAI to ellipticalimpactTime_ut().
            set runmode to runmode + 1.
         }
      }
   } else if runmode = 1 { //Warp to approach
      if accurateTAI - burn_length(velocityAt(ship, accurateTAI):surface:mag) > time:seconds + 280 {
         if kuniverse:timewarp:warp = 0 and kuniverse:timewarp:rate = 1 and Kuniverse:timewarp:issettled() {
            until kuniverse:timewarp:warp <> 0 or kuniverse:timewarp:rate <> 1 or not Kuniverse:timewarp:issettled()
               kuniverse:timewarp:warpto(accurateTAI - burn_length(velocityAt(ship, accurateTAI):surface:mag) - 279).
            wait until kuniverse:timewarp:warp = 0 and kuniverse:timewarp:rate = 1 and Kuniverse:timewarp:issettled().
            set runmode to runmode + 1.
         }
      } else set runmode to runmode + 1.
   } else if runmode = 2 { // Set controls for approach
      if accurateTAI - burn_length(velocityAt(ship, accurateTAI):surface:mag) < time:seconds + 280 {
         gear on.
         if vang(ship:facing:forevector, ship:retrograde:forevector) < 0.5 {
            //lock steering to steeringFunction().
            //lock throttle to throttleFunction().
            set runmode to runmode + 1.
         }
      }
   } else if runmode = 3 { // Wait for touchdown
         throttleFunction().
         if alt:radar < h-corePosition and ship:velocity:surface:mag < 0.5 set runmode to runmode + 1.
   } else if runmode = 4 { // Touchdown
      lock throttle to 0.
      lock steering to geo_normalvector(ship:geoposition, 1).
      if ship:velocity:surface:mag < 0.1 set runmode to runmode + 1.
   }
}
print "done.".
