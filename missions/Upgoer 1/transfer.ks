   declare function hillclimb_patch {
      parameter mnode.
      parameter target.

      local step is 1.
      local last is mnode:orbit:nextpatch:periapsis.
      until false {
         if not mnode:orbit:hasnextpatch {
            clearscreen.
            print mnode.
            return OP_FINISHED.
         }
         local current is abs(target - mnode:orbit:nextpatch:periapsis).
         local right is 0.
         local left is 0.
         set mnode:prograde to mnode:prograde + step.
         if mnode:orbit:hasnextpatch set right to abs(target - mnode:orbit:nextpatch:periapsis).
         set mnode:prograde to mnode:prograde - step.
            
         set mnode:prograde to mnode:prograde - step.
         if mnode:orbit:hasnextpatch set left to abs(target - mnode:orbit:nextpatch:periapsis).
         set mnode:prograde to mnode:prograde + step.

         if (left = 0 AND right = 0) OR last <= current {
            if step < 0.0001 return OP_FINISHED.
            set step to step/2.
         } else if  current > right OR current > left {
            if right > left {
               set mnode:prograde to mnode:prograde + step.
            } else {
               set mnode:prograde to mnode:prograde - step.
            }
         } else {
            return OP_FINISHED.
         }
         set last to current.
      }
   }

   declare function transferFinder {
      parameter tgt is body("Mun").

      local t is time:seconds + 180.
      local radial is 0.
      local normal is 0.
      local pro is 0.
      local n is node(t, radial, normal, pro).

      local munPe is 2429600.
      local lastPe is 2429600.
      add(n).
      until false {
         if n:orbit:hasnextpatch {
            return hillclimb_patch(n, 10000).
            print "true munPe: "+n:orbit:nextpatch:periapsis at(0, 15).
            print "munPe: "+munPe at(0, 16).
            if n:orbit:nextpatch:periapsis < 10000 or lastPe < n:orbit:nextpatch:periapsis {
               return OP_FINISHED.
            }
            if n:orbit:nextpatch:periapsis < munPe {
               set munPe to n:orbit:nextpatch:periapsis.
            }else if n:orbit:nextpatch:periapsis > munPe {
              set lastPe to n:orbit:nextpatch:periapsis.
              set t to t + 1.
            }
         } else {
            if (n:orbit:apoapsis+ship:body:radius) < tgt:orbit:semimajoraxis {
               set pro to pro + 1.
            } else if (n:orbit:apoapsis+ship:body:radius) > tgt:orbit:semimajoraxis+1 {
               set pro to pro - 1.
            }
            if (n:orbit:apoapsis+ship:body:radius) >= tgt:orbit:semimajoraxis {
              set t to t + 1.
            }
         }
         set n:eta to t-time:seconds.
         set n:prograde to pro.
      }
      return OP_FINISHED.
   }
//   guidance_ctl:add("findtransfer", transferFinder@).

   declare function phaseAngle {
      parameter startAlt.
      parameter finalAlt.

      local p is 1/(2*sqrt((finalAlt^3)/(((startAlt+finalAlt)/2)^3))).
      local angle is p*360.
      print angle at(0, 10).
      return angle.
   }


