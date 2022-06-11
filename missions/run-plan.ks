@lazyglobal off.
if ship:status = "PRELAUNCH" {
   if not(exists("1:/lib/core/kernel.ksm")) compile "0:/lib/core/kernel.ksm" to "1:/lib/core/kernel.ksm".
   runoncepath("1:/lib/core/kernel.ksm").
   kernel_ctl["load-to-core"]("plans/"+core:tag).
   if not(exists("1:/hiberfile")) create("1:/hiberfile").
   
   kernel_ctl["import-lib"]("plans/"+core:tag).
   //wait until handoff.
   //kernel_ctl["start"]().
} else {
   runoncepath("1:/lib/core/kernel.ksm").
   kernel_ctl["wakeup"]().
   kernel_ctl["start"]().
} 