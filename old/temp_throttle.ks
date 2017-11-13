declare function throttleFunction {
   print "tti elliptical: "+ (ellipticalimpactTime_ut()-time:seconds) at(0, 1).
   print "tti parabolic: " + TTI_adjustedTerrainAtImpact() at(0, 2).
   print "burn length: "+ burn_length(vAtImpact) at(0, 3).
   if calcEnd-calcStart < 0.1 { //Elliptical mode
      print "throttle mode: elliptical" at(0, 0).
         set accurateTAI to ellipticalimpactTime_ut().
         set tti to accurateTAI - time:seconds.
         set vAtImpact to velocityAt(ship, accurateTAI):surface:mag.
         local bl is burn_length(vAtImpact).
         set thrott to max(0, min(1, (thrott + (bl-tti)/max(0.00001, tti)))).
         lock throttle to thrott.
         return.
   } else { //Parabolic mode
      print "throttle mode: parabolic" at(0, 0).
      set tti to TTI_adjustedTerrainAtImpact().
      set vAtImpact to velocityAt(ship, tti+time:seconds):surface:mag.
      local bl is burn_length(vAtImpact).
      set thrott to max(0, min(1, (thrott + (bl-tti)/max(0.00001, tti)))).
      lock throttle to thrott.
      return.
      //if ship:periapsis > 0 and eta:periapsis < eta:apoapsis {
         //local bl is burn_length(velocityAt(ship, time:seconds+eta:periapsis):surface:mag).
         //lock throttle to max(0, min(1, (thrott + (bl-eta:periapsis)/max(0.00001, tti)))).
         //print "before" at(0, 5).
         //return.
      //} else if eta:apoapsis < eta:periapsis and ship:periapsis > -ship:body:radius/2 {
         //local bl is burn_length(velocityAt(ship, time:seconds+eta:apoapsis):surface:mag).
         //lock throttle to max(0, min(1, (thrott + (bl-eta:apoapsis)/max(0.00001, tti)))).
         //return.
      //} else set tti to TTI_adjustedTerrainAtImpact().//timeToImpact_parabolic().
      //if ship:altitude - alt:radar > 1 and max(0, ship:body:geopositionof(positionat(ship, time:seconds+tti)):terrainheight) > max(0, ship:altitude-alt:radar) {
         //local dTerrain is ship:body:geopositionof(positionat(ship, time:seconds+tti)):terrainheight - (ship:altitude-alt:radar).
         //local landscapeSlopeAngle is arctan(dTerrain/(ship:groundspeed*tti)).
         //local localSlopeAngle is vang(geo_normalvector(ship:geoposition, 1), up:forevector). // Geometry...no wait...ALGEBRA says this vang is the same as slope.
         //if landscapeSlopeAngle > localSlopeAngle and ship:verticalspeed < 0 { // landing terrain higher than current
            //lock throttle to 1.
            //return.
         //}
      //}
      //set vAtImpact to abs(ship:verticalspeed)+((ship:body:mu)/((ship:altitude+ship:body:radius)^2))*tti.
      //local bl is burn_length(vAtImpact).
      //if ship:verticalspeed < -1 {
         //set thrott to max(0, min(1, (thrott + (bl-tti)/max(0.00001, tti)))).
         //lock throttle to thrott.
         //return.
      //} else {
         //lock throttle to 0.
         //return.
      //}
   }// else {
      //lock throttle to 1.
      //return.
   //}
}
