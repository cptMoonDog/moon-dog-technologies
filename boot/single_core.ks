@lazyglobal off.
////// Single Core boot /////
// Core nameTag parameters are the same as for lv_boot
// Assumes core nameTag gives the lv name, and ship:name gives the mission
//If this ship is on the launch pad... 
if ship:status = "PRELAUNCH" {
   //IMPORTANT:
   // 1. In the VAB, set the nameTag of this core to the name of lifter definition file in the lv directory.
   // 2. For inclined orbits, append to the nameTag: ", [inclination], [LAN]" 
   // For example, to use the "Spud Atlas" launch vehicle and launch into an orbit coplanar with Minmus,
   // give the core on the launch vehicle the nameTag: "Spud Atlas, 6, 78".
   if core:tag {
      local data is core:tag:split(",").
      if data:length > 1 {
         if data:length = 2 and data[1]:tonumber(-1) = -1 { //Launch to plane of target
            set target to data[1]:trim.
            runpath("0:/lv/"+data[0]+".ks", target:orbit:inclination, target:orbit:lan).
            if target:istype("Vessel") {
               runpath("0:/programs/rendezvous.ks").
               available_programs["rendezvous"](launch_param["upperStage"], target:name).
            } else if target:istype("Body") {
               if target:name = "Minmus" or target:name = "Mun" {
                  runpath("0:/programs/lko-to-moon.ks").
                  runpath("0:/programs/warp-to-soi.ks").
                  runpath("0:/programs/powered-capture.ks").
                  available_programs["lko-to-moon"](target:name, launch_param["upperStage"]).
                  available_programs["warp-to-soi"](target:name).
                  available_programs["powered-capture"](target:name, launch_param["upperStage"]).
               }
            }
         } else if exists("0:/lv/"+data[0]+".ks") { // Launch to defined plane
            local raan is "none".
            local alt is 80000.
            if data:length > 2 set raan to data[2]:tonumber(0).
            if data:length > 3 set alt to data[3]:tonumber(0).
            runpath("0:/lv/"+data[0]+".ks", data[1]:tonumber(0), raan, alt).
         }
      } else {
         runpath("0:/lv/"+data[0]+".ks").
      }
   }
   if exists("0:/missions/"+ship:name+".ks") {
      runpath("0:/missions/"+ship:name+".ks").
   }
   kernel_ctl["start"]().
}
