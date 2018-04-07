@lazyglobal off.

//If this ship is on the launch pad... 
if ship:status = "PRELAUNCH" {
   //Script will look for a mission given by the value of the core's name tag, or the name the vehicle is saved under.
   //If you want a different name for the mission than for the vehicle, tag the core with that name.
   //After launch, the ship will be renamed for with the value of the core's name tag.
   if core:tag and exists("0:/missions/"+core:tag+".ks") {
      set ship:name to core:tag.
      runpath("0:/missions/"+core:tag+".ks").
   } else if exists("0:/missions/"+ship:name+".ks") {
      runpath("0:/missions/"+ship:name+".ks").
   }
}
