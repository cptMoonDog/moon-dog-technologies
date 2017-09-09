//Transfer test
runpath("0:/lib/transfer.ks").
runpath("0:/lib/maneuverControl.ks").
runpath("0:/lib/general.ks").
runpath("0:/lib/core/kernel.ks").

transfer_ctl["etaTarget"]().
maneuver_ctl["add_burn"]("prograde", 350, 72.83687236, "node").
print "Executing..." at(0, 11).
MISSION_PLAN:add(maneuver_ctl["burn_monitor"]).
kernel_ctl["start"]().
