// This bootfile, will compile the given mission file to the core, and set it as the new bootfile.
// The idea is, that a "mission" is the firmware for this particular core.
// The primary reason for doing it this way, is to avoid cluttering up the boot folder with custom boot scripts.

@lazyglobal off.
local landingReserve is 1000.
lock tgt to ship:body:geopositionlatlng(0, 0).
local procs is list().
if ship:status = "PRELAUNCH" {
   wait until ship:status = "FLYING" or ship:status = "SUB_ORBITAL".
   until false {
      if stage:resourceslex["LIQUIDFUEL"]:amount <= landingReserve { // This returns the amount left in whatever is the next thing to be jettisoned.  NOT the currently running total.  If you have side boosters in other words, this is how much is left in THEM, not the main core.  No therefore, we have a problem.  How do we account for side boosters?
         stage.
         lock throttle to 0.
         print stage:resourceslex["LIQUIDFUEL"]:amount.
      }
      list processors in procs.
      if procs:length = 1 {
         wait until ship:altitude > 70000.
         set kuniverse:activeVessel to vessel("Salty Dog 1st Stage Probe").
         // do landing routine
         local retroheadingVec is vxcl(up:forevector, ship:srfretrograde:forevector).
         local tgtHeadingVec is vxcl(up:forevector, tgt:position).
         lock steering to (2*(retroHeadingVec*tgtHeadingVec/tgtHeadingVec:mag)*tgtHeadingVec-retroHeadingVec). // Reflection of retro about tgtHeading.
         wait 100.
      }
   }
}