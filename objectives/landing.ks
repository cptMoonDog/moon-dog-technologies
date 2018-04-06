@lazyglobal off.
{
   available_objectives:add("landing", {
      local pitchangle is 90-vang(up:forevector, ship:srfprograde:forevector).
      local thrott is 0.
      MISSION_PLAN:add({
         //deorbit
         if ship:periapsis > 10000 {
            if not ship:orbit:hasnextpatch {
               warpto(time:seconds+eta:apoapsis).
               lock steering to ship:retrograde.
               wait until vang(ship:facing:forevector, ship:retrograde:forevector) < 1.
               until ship:periapsis < -1000 lock throttle to 1.
            } else { 
               lock steering to ship:retrograde.
               wait 10.
               until ship:periapsis < 1000 lock throttle to 1.
            }
            lock throttle to 0.
            return OP_CONTINUE.
         }
         local ttZeroH is ship:groundspeed/(ship:maxthrust/ship:mass). 
         local vertAccel is -(ship:body:mu/((ship:altitude+ship:body:radius)^2)). //negative is down.
         local ttImpact is (-ship:verticalspeed - sqrt(max(0, ship:verticalspeed^2 - 2*alt:radar*vertAccel)))/(vertAccel).
         clearscreen.
         print "ttzh: "+ttZeroH at(0, 10).
         print "tti: "+ttImpact at(0, 11).
         if ttImpact > ttZeroH+30 and ship:altitude > 10000 {
            set kuniverse:timewarp:warp to min(floor(ship:altitude/15000), kuniverse:timewarp:warp + 1).
            return OP_CONTINUE.
         } else {
            if not (Kuniverse:timewarp:warp = 0) {
               set kuniverse:timewarp:warp to 0.
               lock steering to ship:srfretrograde.
               lock throttle to 0.
               wait until vang(ship:facing:forevector, ship:srfretrograde:forevector) < 1.
            }else {
               if alt:radar > 6 and ship:altitude < 50000 {
                  local pitchLimit is vang(up:forevector, ship:srfretrograde:forevector).
                  local ttZeroV is max(0, ship:verticalspeed/(ship:body:mu/((ship:altitude+ship:body:radius)^2)-ship:maxthrust/ship:mass)). //Assuming full thrust straight up.
                  local ttZeroSrf is ship:velocity:surface:mag/(ship:maxthrust/ship:mass).
                  local pitchMin is min(pitchLimit, (-ship:verticalspeed/ship:velocity:surface:mag)*90).
                  if ttImpact-8 < ttZeroV set pitchangle to max(pitchMin, pitchangle-0.5).
                  else set pitchangle to min(pitchLimit, pitchangle+0.5).
                  print "ttzv: "+ttzeroV at(0, 12).
                  print "ttz: "+ttzeroSrf at(0, 13).
                  print "pitch: "+pitchangle at(0, 14).
                  print "pitchLimit: "+pitchLimit at(0, 15).
                  print "pitchMin: "+pitchMin at(0, 16).

                  if ship:verticalspeed > -10 and ship:verticalspeed < 0 or ship:verticalspeed > 10 lock steering to ship:srfretrograde.
                  else lock steering to up:forevector*angleaxis(pitchangle, ship:srfretrograde:starvector).//min(pitchLimit, max(0,pitchAngle))

                  if ship:verticalspeed > -2 set thrott to 0.
                  else if ttImpact-3 < ttZeroSrf set thrott to min(1, thrott + 0.01).
                  else set thrott to max(0, thrott - 0.01).
                  lock throttle to thrott.

                  //local throttPV is ship:verticalspeed*ship:velocity:surface:mag/alt:radar.
                  //if ship:velocity:surface:mag < 100 or alt:radar > 8500 lock throttle to -(throttPV/sqrt(1+throttPV^2)).
                  //else lock throttle to 1.
                  if alt:radar < 25 {
                     gear on.
                     if ship:velocity:surface:mag > 100 kuniverse:reverttolaunch().
                  }
                  return OP_CONTINUE.
               } else if alt:radar < 6 {
                  lock throttle to 0.
                  lock steering to up.
                  return OP_FINISHED.
               }
            }
         }
      }).
   }).
}
