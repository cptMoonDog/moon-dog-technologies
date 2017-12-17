@lazyglobal off.
declare function pc3 {
if not (defined maneuver_ctl) runpath("0:/lib/maneuver_ctl.ks").
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
available_obj:add("powered-capture", pc3@).
