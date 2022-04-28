@lazyglobal off.
// Title: Return From Orbit
// 
//Objectives and routines will be run in the order they are added here.

runpath("0:/lib/core/kernel.ks").
if not (defined telemetry_ctl) {
   runpath("0:/lib/core/telemetry.ks").
   INTERRUPTS:add(telemetry_ctl["display"]).
}


kernel_ctl["MissionPlanAdd"]({
   lock steering to ship:retrograde.
   wait 30.
   lock throttle to 1.
   wait until ship:periapsis < 45000.
   lock throttle to 0.
   return OP_FINISHED.
}).
kernel_ctl["MissionPlanAdd"]({
   lock steering to ship:north.
   wait 10.
   //stage.
   lock steering to ship:retrograde.
   wait 10.
   unlock steering.
   return OP_FINISHED.
}).
kernel_ctl["MissionPlanAdd"]({
   if ship:altitude < 5000 {
      stage.
      return OP_FINISHED.
   } else return OP_CONTINUE.
}).

