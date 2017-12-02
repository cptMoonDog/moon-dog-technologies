
   declare parameter targetBody.
   declare parameter engineName.
      MISSION_PLAN:add({
      if ship:orbit:body = body(targetBody) {
         maneuver_ctl["add_burn"]("retrograde", engineName, "pe", "circularize").
      }
      return OP_FINISHED.
   }).
   MISSION_PLAN:add(maneuver_ctl["burn_monitor"]).
