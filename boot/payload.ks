@lazyglobal off.

//Boot script for the payload; probe; spacecraft
//  Ship will be renamed to the first parameter in the nameTag of the core on launch.
if ship:status = "PRELAUNCH" {
   //To pass information into this boot script, change the value of the core nameTag.  Format: "[Ship Name]:[Mission Name]".  
   //This keeps it easy to name ships, missions and designs-in-the-hangar differently.
   local mission is "none".
   if core:tag {
      local data is core:tag:split(":").
      runpath("0:/lib/core/kernel.ks").
      if data:length > 1 {
         set ship:name to data[0].
         set core:tag to data[0]. //I know this seems weird, but the lv_boot script needs to be able to identify the payload's processor, and right now, the only way to do that, is if the ship:name and core:tag are the same.
         set mission to data[1]:trim.
         set mission to mission:split(",").  
         MISSION_PLAN:add({
            kernel_ctl["log"]("waiting for handoff...", "status").
            if core:messages:empty return OP_CONTINUE.
            if not core:messages:empty {
               print "handoff accepted".
               set ship:name to data[0].
            } else {
               kernel_ctl["log"]("Handoff failed! Check KOS Module nameTags...", "status").
            }
            return OP_FINISHED.
         }). 
         if exists("0:/missions/"+mission[0]:trim+".ks") {
            if mission:length = 6 runpath("0:/missions/"+mission[0]:trim+".ks", mission[1]:trim, mission[2]:trim, mission[3]:trim, mission[4]:trim, mission[5]:trim).
            else if mission:length = 5 runpath("0:/missions/"+mission[0]:trim+".ks", mission[1]:trim, mission[2]:trim, mission[3]:trim, mission[4]:trim).
            else if mission:length = 4 runpath("0:/missions/"+mission[0]:trim+".ks", mission[1]:trim, mission[2]:trim, mission[3]:trim).
            else if mission:length = 3 runpath("0:/missions/"+mission[0]:trim+".ks", mission[1]:trim, mission[2]:trim).
            else if mission:length = 2 runpath("0:/missions/"+mission[0]:trim+".ks", mission[1]:trim).
            else if mission:length = 1 runpath("0:/missions/"+mission[0]:trim+".ks").
         } 
      } else {
         runpath("0:/missions/std/payload_default.ks").
      }
   } 
}
