@lazyglobal off.

//Boot script for the payload; probe; spacecraft
//  Ship will be renamed to the name of the core on launch,
//  so missions do not necessarily have to have the same name as the craft.
if ship:status = "PRELAUNCH" {
   if core:tag {
      set ship:name to core:tag.
   }
}
print "waiting for handoff...".
wait until not core:messages:empty.
if not core:messages:empty {
   print "handoff accepted".
   if exists("0:/missions/"+core:tag+".ks") {
      runpath("0:/missions/"+core:tag+".ks").
   } 
} else {
   print "Handoff failed! Check KOS Module nameTags...".
}


