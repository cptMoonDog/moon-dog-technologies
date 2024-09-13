@lazyglobal off.

// Boot script for the payload/probe/spacecraft
// To pass information into this boot script, change the value of the core nameTag.  Format: "[Ship Name]:[Mission Name],[PARAMETER1], ..., [PARAMETERn]".  
// Ship will be renamed to the first parameter in the nameTag of the core after the primary launch sequence is complete.
// This keeps it easy to name ships, missions and designs-in-the-hangar differently.

local mission is "none".
local data is list().
if ship:status = "PRELAUNCH" AND core:tag {
   runoncepath("0:/lib/core/kernel.ks").
   set data to core:tag:split(":"). // Payload name: mission, param, param...
   if data:length > 0 {
      set mission to data[1]:split(",")[0]:trim.  // Mission, param, param...
      if exists("0:/missions/"+mission+".ks") {
         deletepath("1:/boot").
         createdir("1:/boot").
         compile "0:/missions/"+mission+".ks" to "1:/boot/"+mission+".ksm".
         set core:bootfilename to "/boot/"+mission+".ksm".
         runpath("1:/boot/"+mission+".ksm").
      }
   }
   // General Payload duties

   // Add program to wait until booster finishes it's job.
   clearscreen.
   set kernel_ctl["status"] to "waiting for handoff...".
   local abort_mode is choose mission_abort if defined mission_abort else {return OP_FINISHED.}.
   kernel_ctl["MissionPlanAdd"]("wait for launch to complete", {
      local procs is list().
      list processors in procs.
      local boosterStillThere is false.
      for p in procs {
         if p:bootfilename = "/boot/lv.ks" or p:bootfilename = "/boot/payload.ksm" {
            set boosterStillThere to true.
            break.
         }
      }
      if core:messages:empty AND boosterStillThere return OP_CONTINUE.
      else {
         if core:messages:empty OR core:messages:peek():content:tostring = "ABORT" {
            if not(core:messages:empty) core:messages:pop().
            set kernel_ctl["status"] to "Aborting...".
            return OP_FAIL.
         } else if core:messages:peek():content:tostring = "SUCCESS" {
            core:messages:pop().
            set kernel_ctl["status"] to "Launch Successful!".
         } else {
            // A different message
         }
         return OP_FINISHED.
      }
   }, abort_mode@ ). 
   kernel_ctl["start"]().
   reboot.
} else if core:messages:length=2 AND (core:messages:peek():content:tostring = "SUCCESS" OR core:messages:peek():content:tostring = "ABORT")  {
   // This path is for the lv.ks script to hand-off execution to payload.ks 
   if core:messages:peek() = "ABORT" {
      if defined mission_abort mission_abort().
      else shutdown.
   } else {
      core:messages:pop().
      set data to core:messages:pop():content:tostring:split(":"). // Payload name: mission, param, param...
      set ship:name to data[0]. // Pop off the first parameter supplied (ship name), and rename the ship.
      set core:tag to data[1].  // Retain parameters for use by the mission file.
      if data:length > 0 {
         set mission to data[1]:split(",")[0]:trim.  // Mission, param, param...
         if exists("0:/missions/"+mission+".ks") {
            deletepath("1:/boot/payload.ksm").
            // Compilation of the mission script to the core, and mission pre-launch configuration, should have already been performed by the lv.ks script.
            set core:bootfilename to "/boot/"+mission+".ksm".
         }
      } else shutdown.
      // Completed Mission Configuration, now reboot and go.
      reboot.
   }
} else {
   print "No Configuration specified".
}
