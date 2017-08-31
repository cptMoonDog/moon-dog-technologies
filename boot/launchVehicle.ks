@lazyglobal off.

if ship:status = "PRELAUNCH" {
   if exists("0:/ships/"+ship:name) and not(exists("1:/"+ship:name)) {
      copypath("0:/ships/"+ship:name, "1:/").
 
      runpath("0:/lib/core/kernel.ks").
      runpath("0:/lib/general.ks").
      runpath("0:/lib/launch/launchControl.ks").
      runpath("0:/lib/maneuverControl.ks").
   }
   if exists(ship:name+"/launch.ks") {
      runpath(ship:name+"/launch.ks").
   }
}//else if ship:status = "SUB_ORBITAL" //Do a boost back and RTLS?
