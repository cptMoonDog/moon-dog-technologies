@lazyglobal off.

if ship:status = "PRELAUNCH" {
   if exists("0:/ships/"+ship:name) and not(exists("1:/"+ship:name)) {
      copypath("0:/ships/"+ship:name, "1:/").
 
      copypath("0:/lib/general.ks", "1:/ascent").
      runpath("1:/ascent/general.ks").

     //Libraries that do not need to be copied to the ship
      runpath("0:/lib/rangeControl.ks").

      //Libraries that DO need to be copied to the ship
      createdir("1:/ascent").
      copypath("0:/lib/core/kernel.ks", "1:/ascent").
      runpath("1:/ascent/kernel.ks").

      copypath("0:/lib/ascent/stagingControl.ks", "1:/ascent").
      runpath("1:/ascent/stagingControl.ks").

      copypath("0:/lib/ascent/steeringControl.ks", "1:/ascent").
      runpath("1:/ascent/steeringControl.ks").

      copypath("0:/lib/ascent/throttleControl.ks", "1:/ascent").
      runpath("1:/ascent/throttleControl.ks").

      copypath("0:/lib/guidanceControl.ks", "1:/ascent").
      runpath("1:/ascent/guidanceControl.ks").
   }
   if exists(ship:name+"/launch.ks") {
      runpath(ship:name+"/launch.ks").
   }
}//else if ship:status = "SUB_ORBITAL" //Do a boost back and RTLS?
