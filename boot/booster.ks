@lazyglobal off.

if ship:status = "PRELAUNCH" {
   if exists("0:/ships/"+ship:name+"/rtls.ks") and not(exists("1:/"+ship:name+"/rtls.ks")) {
      copypath("0:/ships/"+ship:name+"/rtls.ks", "1:/rtls.ks").
}else if ship:status = "SUB_ORBITAL" OR ship:status = "ORBITING" AND //Do a boost back and RTLS?
