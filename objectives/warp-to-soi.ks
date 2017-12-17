@lazyglobal off.

declare function pc2 {
   declare parameter targetBody.
   MISSION_PLAN:add({
      if ship:orbit:hasnextpatch and ship:orbit:nextpatch:body = body(targetBody) {
         if kuniverse:timewarp:warp = 0 and kuniverse:timewarp:rate = 1 and Kuniverse:timewarp:issettled() and ship:orbit:nextpatcheta > 180 {
            warpto(ship:orbit:nextpatcheta+time:seconds-180).
         }
         if kuniverse:timewarp:mode = "PHYSICS" kuniverse:timewarp:cancelwarp.
         return OP_CONTINUE.
      }
      return OP_FINISHED.
   }).
}
available_obj:add("warp-to-soi", pc2@).
