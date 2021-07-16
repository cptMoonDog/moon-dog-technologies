@lazyglobal off.

runpath("0:/lib/core/command_proc.ks").
INTERRUPTS:add(kernel_ctl["command processor"]). 
kernel_ctl["start"]().
