@lazyglobal off.
{
   declare function pc4 {
      local pitchangle is 90-vang(up:forevector, ship:srfprograde:forevector).
      MISSION_PLAN:add({
         //deorbit
         if ship:periapsis > 10000 {
            if not ship:orbit:hasnextpatch {
               warpto(time:seconds+eta:apoapsis).
               lock steering to ship:retrograde.
               wait until eta:apoapsis > eta:periapsis.
               wait 10.
               until ship:periapsis < -1000 lock throttle to 1.
            }
            else { 
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
         if ttImpact < ttZeroH+30 {
            set kuniverse:timewarp:warp to kuniverse:timewarp:warp + 1.
            return OP_CONTINUE.
         }
         else if not Kuniverse:timewarp:warp = 0 {
            set kuniverse:timewarp:warp to 0.
            lock steering to ship:srfretrograde.
            lock throttle to 0.
            wait until vang(ship:facing:forevector, ship:srfretrograde:forevector) < 1.
         }
         if alt:radar > 6 {
            local pitchLimit is vang(up:forevector, ship:srfretrograde:forevector).
            local ttZeroV is max(0, ship:verticalspeed/(ship:body:mu/((ship:altitude+ship:body:radius)^2)-ship:maxthrust/ship:mass)). //Assuming full thrust straight up.
            local pitchMin is (-ship:verticalspeed/ship:velocity:surface:mag)*90.
            if ttImpact-8 < ttZeroV set pitchangle to max(pitchMin, pitchangle-0.5).
            else set pitchangle to min(pitchLimit, pitchangle+0.5).

            if ship:verticalspeed > -10 and ship:verticalspeed < 0 or ship:verticalspeed > 10 lock steering to ship:srfretrograde.
            else lock steering to up:forevector*angleaxis(pitchangle, ship:srfretrograde:starvector).//min(pitchLimit, max(0,pitchAngle))
            local throttPV is ship:verticalspeed*ship:velocity:surface:mag/alt:radar.
            if ship:velocity:surface:mag < 100 or alt:radar > 8500 lock throttle to -(throttPV/sqrt(1+throttPV^2)).
            else lock throttle to 1.
            if alt:radar < 25 {
               gear on.
               if ship:velocity:surface:mag > 100 kuniverse:reverttolaunch().
            }
            return OP_CONTINUE.
         }
         return OP_FINISHED.
      }).
   }
   program_ctl:add("landing", pc4@).
}
