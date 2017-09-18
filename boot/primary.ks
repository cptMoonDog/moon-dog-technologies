@lazyglobal off.

if ship:status = "PRELAUNCH" {
   if exists("0:/missions/"+ship:name+".ks") and not(exists("1:/"+ship:name+".ks")) {
      copypath("0:/missions/"+ship:name+".ks", "1:/").
 
   }
   runpath("1:/"+ship:name+".ks").
}
