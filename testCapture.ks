   MISSION_PLAN:add({
      if ship:orbit:body = body("Minmus") {
         maneuver_ctl["add_burn"]("retrograde", 350, 72.83687236, "pe", "circularize").
      }
      return OP_FINISHED.
   }).
   MISSION_PLAN:add(maneuver_ctl["burn_monitor"]).

   kernel_ctl["start"]().
   set ship:control:pilotmainthrottle to 0.

