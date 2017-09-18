@lazyglobal off.

if ship:status = "PRELAUNCH" {
   if exists("0:/ships/"+ship:name+"/booster.ks") and not(exists("1:/"+ship:name+"/booster.ks")) 
      copypath("0:/ships/"+ship:name+"/booster.ks", "1:/booster.ks").

   runpath("1:/booster.ks").
}//else if ship:status = "SUB_ORBITAL" OR ship:status = "ORBITING"  //Do a boost back and RTLS?
