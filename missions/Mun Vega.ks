@lazyglobal off.
//A mission template

//The Launch Vehicle initializes the system for launch to LKO
runpath("0:/lv/delta5.ks", 0, "none").

runpath("0:/lib/load_objectives.ks", list("lko-to-mun", "warp-to-soi", "powered-capture", "landing")).
add_obj_to_MISSION_PLAN["LKO-to-Mun"]("poodle").
MISSION_PLAN:add({//Ensure that upper stage is ditched, and transfer stage is active.
   wait 5.
   if ship:maxthrust > 1.01*maneuver_ctl["engineStat"]("terrier", "thrust") { //Maxthrust is float, straight comparison sometimes fails. 
      stage.
      return OP_CONTINUE.
   }
   return OP_FINISHED.
}).
add_obj_to_MISSION_PLAN[["warp-to-soi"]("Mun").
MISSION_PLAN:add({
   wait 30.
   return OP_FINISHED.
}).
add_obj_to_MISSION_PLAN["powered-capture"]("Mun", "terrier").
add_obj_to_MISSION_PLAN["landing"]().

//runpath("0:/lv/munar-ascent.ks").
//runpath("0:/programs/return-from-moon.ks").
//runpath("0:/programs/warp-to-soi.ks", "Kerbin").
//runpath("0:/programs/adjust-pe.ks", 34).
//runpath("0:/programs/edl.ks").


//This starts the runmode system
kernel_ctl["start"]().
