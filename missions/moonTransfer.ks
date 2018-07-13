@lazyglobal off.
//A mission template
//Objectives and routines will be run in the order they are added here.
//When writing your own, avoid loops and wait statements.
//If a routine in the MISSION_PLAN list returns OP_CONTINUE, it will be run again,
// if it returns OP_FINISHED, the system will advance to the next routine in the MISSION_PLAN.

//The Launch Vehicle adds launch to LKO to the MISSION_PLAN
//It accepts two parameters: inclination and Longitude of Ascending Node.
//Values for Minmus are 6 and 78 respectively.

declare parameter bod, transferStageEngine, captureStageEngine, finalEngine.

//Load up pluggable objectives.
runpath("0:/programs/lko-to-moon.ks").
runpath("0:/programs/warp-to-soi.ks").
runpath("0:/programs/powered-capture.ks").
runpath("0:/programs/change-ap.ks").
runpath("0:/programs/change-pe.ks").

//Add Pluggable objectives like this:
available_programs["lko-to-moon"](bod, transferStageEngine).
MISSION_PLAN:add({
   print "waiting...".
   wait until ship:orbit:body = body("Mun").
   print "finished waiting...".
   return OP_FINISHED.
}).
available_programs["powered-capture"](bod, captureStageEngine).
MISSION_PLAN:add({
   if ship:periapsis > 250000 {
      available_programs["change-pe"](finalEngine, "250000").
      available_programs["change-ap"](finalEngine, "250000").
   } else {
      available_programs["change-ap"](finalEngine, "250000").
      available_programs["change-pe"](finalEngine, "250000").
   }
   return OP_FINISHED.
}).

//This starts the runmode system
kernel_ctl["start"]().
