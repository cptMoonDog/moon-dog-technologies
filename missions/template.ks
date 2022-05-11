@lazyglobal off.
// A mission template
// Since the Spaceman Spiff update, the paradigm for 'missions' has changed.
// Programs are a series of objectives regardless of size which are run in order, and programs can be made up of other programs.
// Missions on the other hand are best thought of as the firmware of your spacecraft.

// 


if ship:status = "PRELAUNCH" {
   global DEPENDENCIES is list().

   DEPENDENCIES:add("lko-to-moon").  
   DEPENDENCIES:add("powered-capture").  
} else if ship:status = "ORBITING" {
   if exists("1:/kernel.ksm") runoncepath("1:/kernel.ksm").
   kernel_ctl["loadProgram"]("lko-to-moon").
   kernel_ctl["loadProgram"]("powered-capture").
   available_programs["lko-to-moon"]("terrier Mun").
   available_programs["powered-capture"]("terrier Mun").

} else if ship:status = "ESCAPING" {
   if exists("1:/kernel.ksm") runoncepath("1:/kernel.ksm").
   if ship:orbit:hasnextpatch and ship:orbit:nextpatch:body = body("Mun") {
      kernel_ctl["loadProgram"]("powered-capture").
      available_programs["powered-capture"]("terrier Mun").
   }
}
//Objectives and routines will be run in the order they are added here.
//When writing your own, avoid loops and wait statements.
//If a routine in the MISSION_PLAN list returns OP_CONTINUE, it will be run again,
// if it returns OP_FINISHED, the system will advance to the next routine in the MISSION_PLAN.

//Load up pluggable objectives.
//runpath("0:/programs/change-ap.ks").
//runpath("0:/programs/rendezvous.ks").
//runpath("0:/programs/lko-to-mun.ks").
//runpath("0:/programs/warp-to-soi.ks").
//runpath("0:/programs/powered-capture.ks").
//runpath("0:/programs/landing.ks").


//Add Pluggable objectives like this:
//available_programs["lko-to-mun"]("terrier").

//available_programs["rendezvous"]("terrier").
//
//available_programs["warp-to-soi"]("Mun").
//available_programs["powered-capture"]("terrier").
//available_programs["landing"]("terrier").

