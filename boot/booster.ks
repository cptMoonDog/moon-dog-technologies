@lazyglobal off.

declare global bootparams is lexicon().
set bootparams to readjson("0:/boosterconfig.json").
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

runOnVolume("0:/lib/core/kernel.ks").
if bootparams["type"] = "rtls" runOnVolume("0:/missions/rtls.ks").


