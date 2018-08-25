@lazyglobal off.
//A mission template
//Objectives and routines will be run in the order they are added here.
//When writing your own, avoid loops and wait statements.
//If a routine in the MISSION_PLAN list returns OP_CONTINUE, it will be run again,
// if it returns OP_FINISHED, the system will advance to the next routine in the MISSION_PLAN.

//Load up pluggable objectives.
//runpath("0:/programs/return-from-moon.ks").
//runpath("0:/programs/warp-to-soi.ks").
//
//available_programs["return-from-moon"]("terrier").
//available_programs["warp-to-soi"]("Kerbin").
//MISSION_PLAN:add({
//   print "waiting...".
//   wait until ship:orbit:body = body("Kerbin").
//   print "finished waiting...".
//   return OP_FINISHED.
//}).
runpath("0:/lib/core/kernel.ks").
MISSION_PLAN:add({
   if kuniverse:timewarp:warp = 0 and kuniverse:timewarp:rate = 1 and Kuniverse:timewarp:issettled() and ship:altitude > 80000 {
      set warp to 5.
      return OP_CONTINUE.
   } else if kuniverse:timewarp:mode = "PHYSICS" kuniverse:timewarp:cancelwarp.
   return OP_FINISHED.
}).
MISSION_PLAN:add({
   lock steering to ship:north.
   wait 10.
   stage.
   lock steering to ship:retrograde.
   wait 10.
   unlock steering.
   return OP_FINISHED.
}).
MISSION_PLAN:add({
   if ship:altitude < 5000 {
      stage.
      return OP_FINISHED.
   } else return OP_CONTINUE.
}).

//This starts the runmode system
kernel_ctl["start"]().