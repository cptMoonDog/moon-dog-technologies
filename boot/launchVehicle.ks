@lazyglobal off.

if ship:status = "PRELAUNCH" and exists("0:/ships/"+ship:name) and not(exists("1:/"+ship:name)) {
   copypath("0:/ships/"+ship:name, "1:/").
   cd("1:/").
   if exists(ship:name+"/launch.ks") {
      runpath(ship:name+"/launch.ks").
   }
}//else if ship:status = "SUB_ORBITAL" //Do a boost back and RTLS?
