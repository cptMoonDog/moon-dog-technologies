
declare function prefab_LKOToMun {
   declare parameter engineName.
   MISSION_PLAN:add({
      if ship:maxthrust > 1.01*maneuver_ctl["upperStage_stat"](engineName, "thrust") stage. 
      wait 5.
      set target to body("Mun").
      local mnvr is node(transfer_ctl["etaPhaseAngle"]()+time:seconds, 0,0, transfer_ctl["dv"]("Kerbin", "Mun")+20).
      add(mnvr).
      maneuver_ctl["add_burn"]("node", engineName, "node", mnvr:deltav:mag).
      return OP_FINISHED.
   }).
   MISSION_PLAN:add(maneuver_ctl["burn_monitor"]).
}
declare function prefab_warpToSOI {
   declare parameter targetBody.
   MISSION_PLAN:add({
      if ship:orbit:hasnextpatch and ship:orbit:nextpatch:body = body(targetBody) {
         if kuniverse:timewarp:warp = 0 and kuniverse:timewarp:rate = 1 and Kuniverse:timewarp:issettled() and ship:orbit:nextpatcheta > 180 {
            warpto(ship:orbit:nextpatcheta+time:seconds-180).
         }
         return OP_CONTINUE.
      }
      return OP_FINISHED.
   }).
}
declare function prefab_poweredCapture {
   declare parameter targetBody.
   declare parameter engineName.
      MISSION_PLAN:add({
      if ship:orbit:body = body(targetBody) {
         maneuver_ctl["add_burn"]("retrograde", engineName, "pe", "circularize").
      }
      return OP_FINISHED.
   }).
   MISSION_PLAN:add(maneuver_ctl["burn_monitor"]).
}
