@lazyglobal off.

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
         if data:length = 2 and data[1]:tonumber(-1) = -1 {
            set target to data[1]:trim.
            if target:body = ship:body {
               runpath("0:/lv/"+data[0]+".ks", target:orbit:inclination, target:orbit:lan).
            } else print "Bad Launch Target".
         } else if exists("0:/lv/"+data[0]+".ks") {
            local raan is "none".
            local alt is 80000.
            // data[1] is inclination
            if data:length > 2 set raan to data[2]:tonumber(0).
            if data:length > 3 set alt to data[3]:tonumber(0).
            //Order of parameters may not seem to make sense, it is this way to allow the
            //case above, where a launch to a target coplanar orbit is desired.
            runpath("0:/lv/"+data[0]+".ks", data[1]:tonumber(0), raan, alt).
         }
      } else {
         runpath("0:/lv/"+data[0]+".ks").
      }
   } else if exists("0:/lv/"+ship:name+".ks") {
      runpath("0:/lv/"+ship:name+".ks").
   }
   kernel_ctl["start"]().
   //Wait until program is finished, and then wait 5 seconds.
   wait 5.
   local payloadCore is processor(ship:name).
   if payloadCore:tag {
      print "Handing off...".
      payloadCore:connection:sendmessage("handoff").
   }
}
