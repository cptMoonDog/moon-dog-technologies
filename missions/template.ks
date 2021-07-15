@lazyglobal off.
//A mission template
//Objectives and routines will be run in the order they are added here.
//When writing your own, avoid loops and wait statements.
//If a routine in the MISSION_PLAN list returns OP_CONTINUE, it will be run again,
// if it returns OP_FINISHED, the system will advance to the next routine in the MISSION_PLAN.

//Load up pluggable objectives.
//runpath("0:/programs/std/lko-to-mun.ks").
//runpath("0:/programs/std/warp-to-soi.ks").
//runpath("0:/programs/std/powered-capture.ks").
//runpath("0:/programs/std/landing.ks").

// If using the "single_core.ks" boot file,
//The Launch Vehicle adds launch to LKO to the MISSION_PLAN

//Add Pluggable objectives like this:
//available_programs["lko-to-mun"]("terrier").

//You can also add custom routines to the MISSION_PLAN like this:
//MISSION_PLAN:add({
//  if ship:orbit:apoapsis > 80000 {
//    lock throttle to 0.
//    return OP_FINISHED.
//  } else {
//    lock steering to ship:orbit:prograde.
//    lock throttle to 1.
//    return OP_CONTINUE.
//  }
//}).
////Or like this:
//declare function raise_pe {
//  if ship:orbit:periapsis < 75000 {
//    if eta:apoapsis < 10 lock throttle to 1.
//    lock steering to ship:orbit:prograde.
//    return OP_CONTINUE.
//  } else {
//    lock throttle to 0.
//    return OP_FINISHED.
//  }
//}
//MISSION_PLAN:add(raise_pe@).
//
//available_programs["warp-to-soi"]("Mun").
//available_programs["powered-capture"]("terrier").
//available_programs["landing"]("terrier").

// This line calls the kernel to start the runmode system and start execution.
kernel_ctl["start"]().
