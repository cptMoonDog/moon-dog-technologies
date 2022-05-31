@lazyglobal off.
if exists("1:/lib/core/kernel.ks") runpath("0:/lib/core/kernel.ks").
else runpath("0:/lib/core/kernel.ks").

local stowed is readjson("1:/stowed.json").
for k in stowed:keys {
   if exists("0:/programs/"+k+".ks") {
      runpath("0:/programs/"+k+".ks").
      available_programs[k](stowed[k]).
   } else {
      print "Hibernation Error!  Unknown state: "+k.
      shutdown.
   }
}
//deletepath("0:/stowed.json").
kernel_ctl["start"]().