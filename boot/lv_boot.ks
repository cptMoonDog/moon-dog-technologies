@lazyglobal off.

//If this ship is on the launch pad... 
if ship:status = "PRELAUNCH" {
   //IMPORTANT:
   // 1. In the VAB, set the nameTag of this core to the name of lifter definition file in the lv directory.
   // 2. For inclined orbits, append to the nameTag: ", [inclination], [LAN]" 
   // For example, to use the "Spud Atlas" launch vehicle and launch into an orbit coplanar with Minmus,
   // give the core on the launch vehicle the nameTag: "Spud Atlas, 6, 78".
   // Or, just set the nameTag to "Spud Atlas, Minmus"
   if core:tag {
      local data is core:tag:split(",").
      if not(exists("0:/lv/"+data[0]+".ks")) {
         print "Fatal error: No Launch Vehicle definition file".
         shutdown.
      }
      if data:length > 1 {
         if data:length = 2 and data[1]:tonumber(-1) = -1 {
            print "target: "+ data[1].
            if data[1]:trim = "Polar" {
               runpath("0:/lv/"+data[0]+".ks", 90).
            } else {
               set target to data[1]:trim.
               if target:body = ship:body {
                  runpath("0:/lv/"+data[0]+".ks", target:orbit:inclination, target:orbit:lan).
               } else {
                  runpath("0:/lib/physics.ks").
                  local ttWindow is phys_lib["etaPhaseAngle"](body("Kerbin"), target).
                  print ttWindow.
                  //TODO make this work
                  runpath("0:/lv/"+data[0]+".ks").
               }
            }
         } else {
            local raan is "none".
            local alt is 80000.
            // data[1] is inclination
            // data[2] is raan/lan
            // data[3] is target altitude
            if data:length > 2 set raan to data[2]:tonumber(0).
            if data:length > 3 set alt to data[3]:tonumber(0).
            //One might think that the raan/lan should be given last in the parameter list. 
            //However, that would block the case of a launch to LKO in a target-coplanar orbit.
            //That is why altitude is given last; i.e. by default assume all launches want LKO altitude.
            runpath("0:/lv/"+data[0]+".ks", data[1]:tonumber(0), raan, alt).
         }
      } else {
         //If no parameters given; runs the launch with default values
         runpath("0:/lv/"+data[0]+".ks").
      }
   } else if exists("0:/lv/"+ship:name+".ks") {
      //If the nameTag on the core is not used, attempt to find a script with the ship:name instead
      runpath("0:/lv/"+ship:name+".ks").
   }
   kernel_ctl["start"]().
   //Wait until program is finished, and then wait 5 seconds.
   //The following attempts to pass off control of the craft, from the KOS Processor on the Booster, 
   //to the KOS Processor on the payload.
   //For more info, see payload_boot.ks
   wait 5.
   local payloadCore is processor(ship:name).
   if payloadCore:tag {
      print "Handing off...".
      payloadCore:connection:sendmessage("handoff").
   }
   shutdown.
}
