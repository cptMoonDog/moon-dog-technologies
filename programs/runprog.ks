@lazyglobal off.
//Load kernel
runpath("0:/lib/core/kernel.ks").
//load program manager
runpath("0:/lib/program_ctl.ks", list("landing")).

//Load programs into sequence
program_ctl["landing"]().
//Start system running and execute sequence
kernel_ctl["start"]().
