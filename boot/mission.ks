// This bootfile, will compile the given mission file to the core, and set it as the new bootfile.
// The idea is, that a "mission" is the firmware for this particular core.
// The primary reason for doing it this way, is to avoid cluttering up the boot folder with custom boot scripts.

@lazyglobal off.
if ship:status = "PRELAUNCH" {
   local mission is "".
   if core:tag:contains(",") {
      set mission to core:tag:split(",")[0].
      set core:tag to core:tag:remove(0, core:tag:split(",")[0]:length+1):trim().
   } else {
      set mission to core:tag.
      set core:tag to "".
   }
   
   if exists("0:/missions/"+mission+".ks") {
      compile "0:/missions/"+mission+".ks" to "1:/boot/"+mission+".ksm".
      set core:bootfilename to "/boot/"+mission+".ksm".
      reboot.
   }
}