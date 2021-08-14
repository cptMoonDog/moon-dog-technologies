@lazyglobal off.

declare global bootparams is lexicon().
set bootparams to readjson("0:/lvconfig.json").
declare global function runOnVolume {
   parameter externalPath.

   if bootparams["runVolume"] = 1 {
      local newPath is "1:"+externalPath:split(":")[1]:split(".")[0]+".ksm".
      if not(exists(newPath)) {
         compile externalPath to newPath.
      }
      runpath(newPath).
   } else runpath(externalPath).
}

//If this ship is on the launch pad... 
if ship:status = "PRELAUNCH"  {
   //If we are running on the core, compile boot file to save space
   if bootparams["runVolume"] = 1 and scriptpath():split(".")[1] = "ks" {
      local archivePath is "0:"+scriptpath():split(":")[1].
      local newPath is scriptpath():split(".")[0]+".ksm".
      compile archivePath to newPath.
      set core:bootfilename to newPath:split(":")[1].
      deletepath(scriptpath()).
      reboot.
   }
   if bootparams:haskey("onOrbitBoot") compile "0:/"+bootparams["onOrbitBoot"]+".ks" to "1:/boot/onOrbit.ksm".
      
   runOnVolume("0:/lib/launch/boot_common.ks").
   kernel_ctl["start"]().

   if bootparams:haskey("onOrbitBoot") {
      set core:bootfilename to "/boot/onOrbit.ksm".
      reboot.
   }
} else if ship:status = "ORBITING" {
   if bootparams:haskey("onOrbitBoot") {
      set core:bootfilename to "/boot/onOrbit.ksm".
      reboot.
   }
}
