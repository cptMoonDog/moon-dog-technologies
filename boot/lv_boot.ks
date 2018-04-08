@lazyglobal off.

//If this ship is on the launch pad... 
if ship:status = "PRELAUNCH" {
   //IMPORTANT:
   // 1) In the VAB, set the nameTag of this core to the name of lifter definition file in the lv directory.
   // 2) For inclined orbits, append to the nameTag: ", [inclination], [LAN]" 
   // For example, to use the "Spud Atlas" launch vehicle and launch into an orbit coplanar with Minmus,
   // give the core on the launch vehicle the nameTag: "Spud Atlas, 6, 78".
   if core:tag {
      local data is core:tag:split(",").
      if data:length > 1 {
         exists("0:/lv/"+data[0]+".ks").
         local raan is "none".
         if data:length > 2 set raan to data[2]:tonumber(0).
         runpath("0:/lv/"+data[0]+".ks", data[1]:tonumber(0), raan).
      } else {
         runpath("0:/lv/"+data[0]+".ks").
      }
      kernel_ctl["start"]().
   } 
} else {
   local payloadCore is processor(ship:name).
   payloadCore:connection:sendmessage("handoff").
}
