@lazyglobal off.
//A mission template
//Objectives and routines will be run in the order they are added here.
//When writing your own, avoid loops and wait statements.
//If a routine in the MISSION_PLAN list returns OP_CONTINUE, it will be run again,
// if it returns OP_FINISHED, the system will advance to the next routine in the MISSION_PLAN.

declare parameter newAp.
declare parameter engineName.
//Load up pluggable objectives.
runpath("0:/programs/std/change-ap.ks").
runpath("0:/programs/std/circularize-at-ap.ks").


if newAp:istype("String") set newAp to newAp:tonumber(-1).
if newAp = -1 { 
   print "Input failure!  Ap unrecognizable".
   exit.
}
//Add Pluggable objectives like this:
available_programs["change-ap"](newAp, engineName).
available_programs["circularize-at-ap"](engineName).
print "hohmann mission loaded".