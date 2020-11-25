@lazyglobal off.
////// Single Core boot /////
// Core nameTag parameters are the same as for lv_boot:
   //IMPORTANT:
   // 1. In the VAB, set the nameTag of this core to the name of lifter definition file in the lv directory.
   // 2. For inclined orbits, append to the nameTag: ", [inclination], [LAN]" 
   // For example, to use the "Spud Atlas" launch vehicle and launch into an orbit coplanar with Minmus,
   // give the core on the launch vehicle the nameTag: "Spud Atlas, 6, 78".
   // Or, just set the nameTag to "Spud Atlas, Minmus"
// Assumes core nameTag gives the lv name, and ship:name gives the mission
//If this ship is on the launch pad... 
if ship:status = "PRELAUNCH" {
   runpath("0:/boot/common.ks").
   if HASTARGET and target:body = ship:body { /// Targets in orbit of Origin Body ///
      if target:istype("Vessel") {
         runpath("0:/programs/std/rendezvous.ks").
         available_programs["std/rendezvous"](launch_param["upperStage"], target:name).
      } else if target:istype("Body") {
         runpath("0:/missions/std/moonTransfer.ks", target:name, launch_param["upperStage"],launch_param["upperStage"],launch_param["upperStage"]).
      }
   }
   if exists("0:/missions/"+ship:name+".ks") {
      runpath("0:/missions/"+ship:name+".ks").
   }
   kernel_ctl["start"]().
}
