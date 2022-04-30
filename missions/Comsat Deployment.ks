@lazyglobal off.

//Load up pluggable objectives.
runpath("0:/programs/change-pe.ks").
kernel_ctl["MissionPlanAdd"]("compile new bootfile", {
   compile "0:/missions/bootable-deploy-constellation.ks" to "1:/deploy.ksm".
   set core:bootfilename to "/deploy.ksm".
   return OP_FINISHED.
}).
available_programs["change-pe"]("terrier", 294684).
kernel_ctl["MissionPlanAdd"]("reboot", {
   print "rebooting".
   wait 5.
   reboot.
}).
