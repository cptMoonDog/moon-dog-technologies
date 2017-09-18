@lazyglobal off.

if ship:status = "PRELAUNCH" {
   if exists("0:/mission/"+ship:name) and not(exists("1:/"+ship:name)) {
      copypath("0:/mission/"+ship:name, "1:/").
 
   }
   if exists(ship:name+"/launch.ks") {
      runpath(ship:name+"/launch.ks").
   }
}
