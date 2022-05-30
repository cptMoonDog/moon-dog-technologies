@lazyglobal off.
runpath("0:/lib/core/kernel.ks").
runpath("0:/plans/kerbin-to-mun.ks").
if exists("0:/mission-tracker.txt") {
   local currentProcess is open("0:/mission-tracker.txt"):readall:string:trim.
   until kernel_ctl["MissionPlanList"]()[0] = currentProcess {
      kernel_ctl["MissionPlanRemove"](0).
   }
}
kernel_ctl["start"]().