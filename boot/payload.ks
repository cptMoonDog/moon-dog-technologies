@lazyglobal off.

// Boot script for the payload/probe/spacecraft
// To pass information into this boot script, change the value of the core nameTag.  Format: "[Ship Name]:[Mission Name],[PARAMETER1], ..., [PARAMETERn]".  
// Ship will be renamed to the first parameter in the nameTag of the core after the primary launch sequence is complete.
// This keeps it easy to name ships, missions and designs-in-the-hangar differently.
local mission is "none".
local data is list().
if ship:status = "PRELAUNCH" and core:tag {
   set data to core:tag:split(":"). // Payload name: mission, param, param...
} else if core:messages:length and core:messages:peek():content:tostring = "launch complete" {
   core:messages:pop().
   set data to core:messages:peek():content:tostring:split(":"). // Payload name: mission, param, param...
}
runpath("0:/lib/core/kernel.ks").

// Deal with parameters
if data:length > 0 {
   set mission to data[1]:split(",")[0].  // Mission, param, param...
   if exists("0:/missions/"+mission+".ks") {
      deletepath("1:/boot").
      createdir("1:/boot").
      compile "0:/missions/"+mission+".ks" to "1:/boot/"+mission+".ksm".
      set core:bootfilename to "/boot/"+mission+".ksm".
      // Add program to wait until booster finishes it's job.
      kernel_ctl["MissionPlanAdd"]("wait for launch to complete", {
         set kernel_ctl["status"] to "waiting for handoff...".
         if core:messages:empty return OP_CONTINUE.
         if not core:messages:empty {
            set kernel_ctl["status"] to "handoff accepted.".
            set ship:name to data[0]. // Pop off the first parameter supplied (ship name), and rename the ship.
            set core:tag to data[1].  // Retain parameters for use by the mission file.
            return OP_FINISHED. 
         } else {
            set kernel_ctl["status"] to "Handoff failed!".
            return OP_FAIL.
         }
      }). 
      kernel_ctl["start"]().
      reboot.
   } else {
      print "Mission does not exist!".
      shutdown.
   }
} else {
   print "No Mission specified".
}
   
