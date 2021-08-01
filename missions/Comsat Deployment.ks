@lazyglobal off.
//A mission template
//Objectives and routines will be run in the order they are added here.
//When writing your own, avoid loops and wait statements.
//If a routine in the MISSION_PLAN list returns OP_CONTINUE, it will be run again,
// if it returns OP_FINISHED, the system will advance to the next routine in the MISSION_PLAN.

//Load up pluggable objectives.
runpath("0:/programs/std/change-pe.ks").
MISSION_PLAN:add({
   compile "0:/missions/bootable-deploy-constellation.ks" to "1:/deploy.ksm".
   set core:bootfilename to "/deploy.ksm".
   return OP_FINISHED.
}).
available_programs["change-pe"]("terrier", 294684).
MISSION_PLAN:add({
   print "rebooting".
   wait 5.
   reboot.
}).
