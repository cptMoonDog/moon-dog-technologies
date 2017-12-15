@lazyglobal off.
//A mission template

//The Launch Vehicle handles launch to LKO
runpath("0:/lv/delta5.ks", 0, "none").

local objectives is list("lko-to-mun", "warp-to-soi", "powered-capture", "landing").
runpath("0:/lib/program_ctl.ks", objectives).
program_ctl["LKO-to-Mun"]("poodle").
MISSION_PLAN:add({
   wait 5.
   if ship:maxthrust > 1.01*maneuver_ctl["engineStat"]("terrier", "thrust") { //Maxthrust is float, straight comparison sometimes fails. 
      stage.
      return OP_CONTINUE.
   }
   return OP_FINISHED.
}).
program_ctl["warp-to-soi"]("Mun").
MISSION_PLAN:add({
   wait 30.
   return OP_FINISHED.
}).
program_ctl["powered-capture"]("Mun", "terrier").
program_ctl["landing"]().

//runpath("0:/lv/munar-ascent.ks").
//runpath("0:/programs/return-from-moon.ks").
//runpath("0:/programs/warp-to-soi.ks", "Kerbin").
//runpath("0:/programs/adjust-pe.ks", 34).
//runpath("0:/programs/edl.ks").


//This starts the runmode system
kernel_ctl["start"]().
