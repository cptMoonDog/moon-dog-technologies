@lazyglobal off.
runpath("0:/lib/core/kernel.ks").
local stowed is readjson("0:/stowed.json").
for k in stowed:keys {
   if exists("0:/programs/"+k+".ks") {
      runpath("0:/programs/"+k+".ks").
      available_programs[k](stowed[k]).
   } else {
      print "Hibernation Error!  Unknown state: "+k.
      return 1.
   }
}
//deletepath("0:/stowed.json").
kernel_ctl["start"]().