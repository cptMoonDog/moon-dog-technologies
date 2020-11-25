@lazyglobal off.

//If this ship is on the launch pad... 
if ship:status = "PRELAUNCH" {
   runpath("0:/boot/common.ks").
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
