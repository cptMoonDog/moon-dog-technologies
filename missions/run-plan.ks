@lazyglobal off.
if ship:status = "PRELAUNCH" {
   if not(exists("1:/lib/core/kernel.ksm")) compile "0:/lib/core/kernel.ksm" to "1:/lib/core/kernel.ksm".
   if not(exists("1:/plans/"+core:tag+".ksm")) compile "0:/plans/"+core:tag+".ksm" to "1:/plans/"+core:tag+".ksm".
   if not(exists("1:/hiberfile")) create("1:/hiberfile").
   runoncepath("1:/lib/core/kernel.ksm").
   runoncepath("1:/plans/"+core:tag+".ksm").
   //wait until handoff.
} else {
    runoncepath("1:/lib/core/kernel.ksm").
   runoncepath("1:/plans/"+core:tag+".ksm").
   kernel_ctl["setrunmode"](open("1:/hiberfile"):readall:string:tonumber(0)).
   kernel_ctl["start"]().
} 