@lazyglobal off.

if ship:status = "PRELAUNCH" {
   if exists("0:/ships/"+ship:name) and not(exists("1:/"+ship:name)) {
      copypath("0:/ships/"+ship:name, "1:/").
      copypath("0:/lib/core/kernel.ks", "1:/").
      copypath("0:/lib/maneuverControl.ks", "1:/").
      copypath("0:/lib/general.ks", "1:/").
 
      runpath("0:/lib/launch/launchControl.ks").
      runpath("0:/lib/transfer.ks").

      runpath("1:/kernel.ks").
      runpath("1:/general.ks").
      runpath("1:/maneuverControl.ks").
   }
   if exists(ship:name+"/launch.ks") {
      runpath(ship:name+"/launch.ks").
   }
}//else if ship:status = "SUB_ORBITAL" //Do a boost back and RTLS?
