@lazyglobal off.

runpath("0:/lib/core/command_proc.ks").
INTERRUPTS:add(kernel_ctl["command processor"]). 
MISSION_PLAN:add({
   until kernel_ctl["output"] = "exit" {
      return OP_CONTINUE.
   }
   return OP_FINISHED.
}).
kernel_ctl["start"]().
