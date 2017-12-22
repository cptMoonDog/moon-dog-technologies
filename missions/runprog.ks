@lazyglobal off.
//Load kernel
runpath("0:/lib/core/kernel.ks").
//load program manager
runpath("0:/lib/load_objectives.ks", list("landing", "munar-ascent")).

//Load programs into sequence
add_obj_to_MISSION_PLAN["landing"]().
MISSION_PLAN:add({
   wait 30.
   return OP_FINISHED.
}).
add_obj_to_MISSION_PLAN["munar-ascent"]().

//Start system running and execute sequence
kernel_ctl["start"]().
