@lazyglobal off.
//A mission template
//Objectives and routines will be run in the order they are added here.
//When writing your own, avoid loops and wait statements.
//If a routine in the MISSION_PLAN list returns OP_CONTINUE, it will be run again,
// if it returns OP_FINISHED, the system will advance to the next routine in the MISSION_PLAN.

//The Launch Vehicle adds launch to LKO to the MISSION_PLAN
//It accepts two parameters: inclination and Longitude of Ascending Node.
//Values for Minmus are 6 and 78 respectively.

// The kernel really should be loaded by now.
// These mission files are simply run with no checks, so you can do anything you want with them, but if you intend to use the runmode system,
// don't count on it being pulled by some other initializer.
if not (defined kernel_ctl) runpath("0:/lib/core/kernel.ks"). 

declare parameter bod, transferStageEngine, captureStageEngine, finalEngine.
declare parameter sma is 250000.

//Load up pluggable objectives.
runpath("0:/programs/lko-to-moon.ks").
runpath("0:/programs/warp-to-soi.ks").
runpath("0:/programs/powered-capture.ks").
runpath("0:/programs/change-ap.ks").
runpath("0:/programs/change-pe.ks").

//Add Pluggable objectives like this:
available_programs["lko-to-moon"](transferStageEngine:tostring+" "+bod:tostring).
kernel_ctl["MissionPlanAdd"]({
   set kernel_ctl["status"] to "waiting...".
   if not (ship:orbit:body = body(bod)) return OP_CONTINUE.
   set kernel_ctl["status"] to "finished waiting...".
   return OP_FINISHED.
}).
available_programs["powered-capture"](captureStageEngine:tostring+" "+bod:tostring).
kernel_ctl["MissionPlanAdd"]({
   if ship:periapsis > 250000 {
      available_programs["change-pe"](finalEngine:tostring+" "+sma:tostring).
      available_programs["change-ap"](finalEngine:tostring+" "+sma:tostring).
   } else {
      available_programs["change-ap"](finalEngine:tostring+" "+sma:tostring).
      available_programs["change-pe"](finalEngine:tostring+" "+sma:tostring).
   }
   return OP_FINISHED.
}).

