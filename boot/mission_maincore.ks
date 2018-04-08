@lazyglobal off.

//Boot script for the payload; probe; spacecraft
//  Ship will be renamed to the name of the core on launch,
//  so missions do not necessarily have to have the same name as the craft.
if core:tag {
   set ship:name to core:tag.
}
wait until not core:messages:empty.
print "handoff accepted".
if exists("0:/missions/"+core:tag+".ks") {
   runpath("0:/missions/"+core:tag+".ks").
} 
