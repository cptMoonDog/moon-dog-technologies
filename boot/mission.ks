// This bootfile, will compile the given mission file to the core, and set it as the new bootfile.
// The idea is, that a "mission" is the firmware for this particular core.
// The primary reason for doing it this way, is to avoid cluttering up the boot folder with custom boot scripts.

@lazyglobal off.
if ship:status = "PRELAUNCH" {
   if exists("0:/missions/"+core:tag+".ks") {
      compile "0:/missions/"+core:tag+".ks" to "1:/boot/"+core:tag+".ksm".
      set core:bootfilename to "/boot/"+core:tag+".ksm".
      reboot.
   }
}