@lazyglobal off.
////// Single Core boot /////
// Core nameTag parameters are the same as for lv:
   //IMPORTANT:
   // 1. In the VAB, set the nameTag of this core to the name of lifter definition file in the lv directory.
   // 2. For inclined orbits, append to the nameTag: ", [inclination], [LAN]" 
   // For example, to use the "Spud Atlas" launch vehicle and launch into an orbit coplanar with Minmus,
   // give the core on the launch vehicle the nameTag: "Spud Atlas, 6, 78".
   // Or, just set the nameTag to "Spud Atlas, Minmus"
// Assumes core nameTag gives the lv name, and ship:name gives the mission
//If this ship is on the launch pad... 
if ship:status = "PRELAUNCH" {
   runpath("0:/lib/launch/boot_common.ks").
   if HASTARGET and target:body = ship:body { /// Targets in orbit of Origin Body ///
      if target:istype("Vessel") {
         runpath("0:/programs/rendezvous.ks").
         available_programs["rendezvous"](launch_param["upperStage"], target:name).
      } else if target:istype("Body") {
         runpath("0:/programs/lko-to-moon.ks").
         runpath("0:/programs/powered-capture.ks").
         available_programs["lko-to-moon"](target:name, launch_param["upperStage"]).
         available_programs["powered-capture"](target:name, launch_param["upperStage"]).
      }
   }
   // The limitation here, is the you cannot provide the same information as to a seperate payload.
   // The core:tag data is reserved for the booster launch.  
   if exists("0:/missions/"+ship:name+".ks") {
      compile "0:/missions/"+ship:name+".ks" to "1:/boot/"+ship:name+".ksm".
      set core:bootfilename to "/boot/"+ship:name+".ksm".
   }
   kernel_ctl["start"]().
   reboot.
}
