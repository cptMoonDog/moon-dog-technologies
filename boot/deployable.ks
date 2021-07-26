@lazyglobal off.
copypath("0:/lib/maneuver_ctl.ks", "1:/maneuver_ctl.ks").
copypath("0:/lib/core/kernel.ks", "1:/kernel.ks").
copypath("0:/programs/std/circularize-at-ap.ks", "1:/circ.ks").
runpath("1:/kernel.ks").
runpath("1:/maneuver_ctl.ks").
runpath("1:/circ.ks").
local procs is list().
until procs:length = 1{
   list processors in procs.
}
available_programs["circularize-at-ap"]("ant").

kernel_ctl["start"]().
