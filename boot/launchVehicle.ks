@lazyglobal off.

if ship:status = "PRELAUNCH" {
   if exists("0:/ships/"+ship:name) and not(exists("1:/"+ship:name)) {
      copypath("0:/ships/"+ship:name, "1:/").
 
      runpath("0:/lib/general.ks").

     //Libraries that do not need to be copied to the ship
      runpath("0:/lib/rangeControl.ks").

      //Libraries that DO need to be copied to the ship
      runpath("0:/lib/core/kernel.ks").

      runpath("0:/lib/ascent/stagingControl.ks").

      runpath("0:/lib/ascent/steeringControl.ks").

      runpath("0:/lib/ascent/throttleControl.ks").

      runpath("0:/lib/guidanceControl.ks").
   }
   if exists(ship:name+"/launch.ks") {
      runpath(ship:name+"/launch.ks").
   }
}//else if ship:status = "SUB_ORBITAL" //Do a boost back and RTLS?
