@lazyglobal off.
declare function pc1 {
   declare parameter engineName.
   if not (defined transfer_ctl) runpath("0:/lib/transfer_ctl.ks").
   if not (defined maneuver_ctl) runpath("0:/lib/maneuver_ctl.ks").
   MISSION_PLAN:add({
      if ship:maxthrust > 1.01*maneuver_ctl["engineStat"](engineName, "thrust") {
         print engineName.
         if not (engineName =  "poodle") kuniverse:reverttolaunch. 
         stage. 
      }
      wait 5.
      set target to body("Mun").
      local mnvr is node(transfer_ctl["etaPhaseAngle"]()+time:seconds, 0,0, transfer_ctl["dv"]("Kerbin", "Mun")+20).
      add(mnvr).
      maneuver_ctl["add_burn"]("node", engineName, "node", mnvr:deltav:mag).
      return OP_FINISHED.
   }).
   MISSION_PLAN:add(maneuver_ctl["burn_monitor"]).
}
program_ctl:add("LKO-to-Mun", pc1@).
