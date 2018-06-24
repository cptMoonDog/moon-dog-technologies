@lazyglobal off.

//Boot script for the payload; probe; spacecraft
//  Ship will be renamed to the name of the core on launch,
//  so missions do not necessarily have to have the same name as the craft.
if ship:status = "PRELAUNCH" {
   //To pass information into this boot script, change the value of the core nameTag.  Format expected: "[Ship Name]:[Mission Name]".  
   //This keeps it easy to name ships, missions and designs in the hangar differently.
   local mission is "none".
   if core:tag {
      local data is core:tag:split(":").
      if data:length > 1 {
         set ship:name to core:tag.
         set mission to data[1]:trim.
      }
      print "waiting for handoff...".
      wait until not core:messages:empty.
      if not core:messages:empty {
         print "handoff accepted".
         set ship:name to data[0].
         if exists("0:/missions/"+mission+".ks") {
            runpath("0:/missions/"+mission+".ks").
         } 
      } else {
         print "Handoff failed! Check KOS Module nameTags...".
      }
   } 
}