runpath("0:/engine-conf.ks").

   declare parameter engineName.
   MISSION_PLAN:add({
      if ship:maxthrust > 1.01*engineStat(engineName, "thrust") stage. 
      wait 5.
      set target to body("Mun").
      local mnvr is node(transfer_ctl["etaPhaseAngle"]()+time:seconds, 0,0, transfer_ctl["dv"]("Kerbin", "Mun")+20).
      add(mnvr).
      maneuver_ctl["add_burn"]("node", engineName, "node", mnvr:deltav:mag).
      return OP_FINISHED.
   }).
   MISSION_PLAN:add(maneuver_ctl["burn_monitor"]).
