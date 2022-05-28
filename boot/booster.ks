// This bootfile, will compile the given mission file to the core, and set it as the new bootfile.
// The idea is, that a "mission" is the firmware for this particular core.
// The primary reason for doing it this way, is to avoid cluttering up the boot folder with custom boot scripts.

@lazyglobal off.
if ship:status = "PRELAUNCH" {
   wait until not(core:messages:empty).
   print "booster routine initiated".
}