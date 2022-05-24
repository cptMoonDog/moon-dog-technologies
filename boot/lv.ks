@lazyglobal off.

//If this ship is on the launch pad... 
if ship:status = "PRELAUNCH" {
   runpath("0:/lib/launch/boot_common.ks").
   kernel_ctl["start"]().
   //Wait until program is finished, and then wait 5 seconds.
   //The following attempts to pass off control of the craft, from the KOS Processor on the Booster, 
   //to the KOS Processor on the payload.
   //For more info, see payload_boot.ks
   wait 5.
   local procs is list().
   list processors in procs.
   for payloadCore in procs {
         print "Handing off...".
         payloadCore:connection:sendmessage("launch complete").
   }
   shutdown.
}
