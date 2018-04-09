@lazyglobal off.

//If this ship is on the launch pad... 
if ship:status = "PRELAUNCH" {
   //Script will look for a Launch Vehicle given by the value of the core's name tag.
   if core:tag and exists("0:/missions/"+core:tag+".ks") {
      set ship:name to core:tag.
   } 
   if exists("0:/missions/"+ship:name+".ks") runpath("0:/missions/"+ship:name+".ks").
}
