@lazyglobal off.

//If this ship is on the launch pad... 
if ship:status = "PRELAUNCH" {
   //// Locate launch parameters
   local data is list().
   local payloadData is "".
   if core:tag set data to core:tag:split(","). // Parameters are in the core:tag
   else if exists("0:/launchparameters.txt") {  // Parameters are in this file.
      print "found parameters file".
      local f is open("0:/launchparameters.txt").
      local i is f:readall:iterator.
      i:next.
      until i:atend {
         if i:value:tostring:trim:tolower:startswith("//launch") {
            print "found launch data".
            i:next.
            set data to i:value:tostring:split(",").
         } else if i:value:tostring:trim:tolower:startswith("//payload") { // Also contains parameters we are going to pass off to the payload script.
            print "found payload data".
            i:next.
            set payloadData to i:value.
         } else i:next.
      }
      if payloadData {
         print "changed bootfile".
         copypath("0:/boot/payload.ks", "1:/boot/payload.ks").
         set core:bootfilename to "/boot/payload.ks".
      }
   }

   // A convenience function 
   declare local function setLaunchParams {
      parameter inclination is 0.
      parameter lan is "none".

      launch_param:add("inclination", inclination).
      if lan = -1 set lan to "none".
      launch_param:add("lan", lan).

      if launch_param["lan"]="none" or abs(launch_param["inclination"]) < 1 or launch_param["inclination"] = 180 {             
         launch_param:add("launchTime",        "now"). 
      } else if lan:istype("Scalar") {
         launch_param:add("launchTime",        "window"). 
      }
   }

   if data:length > 0 {  
      runoncepath("0:/lib/core/kernel.ks").
      runoncepath("0:/lib/launch/launch_ctl.ks").
      if not(exists("0:/lv/"+data[0]+".ks")) {
         print "Fatal error: No Launch Vehicle definition file".
         shutdown.
      }
      if data:length > 1 {
         // Target handling
         if data:length = 2 and data[1]:tonumber(-1) = -1 { // Second parameter is not numeric.
            print "target: "+ data[1].
            if data[1]:trim = "Polar" { /// Dummy Targets ///
               setLaunchParams(90, 0).
               kernel_ctl["import-lib"]("lv/"+data[0]).
            } else {
               set target to data[1]:trim.
               if target:body = ship:body { /// Targets in orbit of Origin Body ///
                  if abs(target:orbit:inclination) < 1 and abs(ship:latitude) < 1 {
                     print "inc: "+target:orbit:inclination at(0, 9).
                     print "lat: "+ship:latitude at(0, 8).
                     launch_param:add("orbitType", "rendezvous").
                     setLaunchParams(0, "none").
                  } else setLaunchParams(target:orbit:inclination, target:orbit:lan).
                  kernel_ctl["import-lib"]("lv/"+data[0]).
               } else { /// Interplanetary Targets ///
                  // All interplanetary trajectories start from equatorial orbit.
                  setLaunchParams(0, "none").
                  launch_param:add("targetApo", 80000).
                  kernel_ctl["import-lib"]("lv/"+data[0]).
               }
            }
         } else { /// Defined orbit, 
            launch_param:add("targetApo", 80000).
            // data[1] is inclination
            // data[2] is raan/lan
            // data[3] is Orbit altitude
            if data:length > 2 setLaunchParams(data[1]:tonumber(0), data[2]:tonumber(-1)).
            if data:length > 3 {
               if data[3]:contains("to:") { //Transfer Orbit, altitude of apoapsis of the transfer orbit.
                  launch_param:add("orbitType", "transfer").  //If transfer is selected, circularization is not performed and payload is expected to takeover.
                  set launch_param["targetApo"] to data[3]:split(":")[1]:tonumber(80)*1000. //Transfer orbits are so high, we require them reduced by 1000.
               } else {
                  set launch_param["targetApo"] to data[3]:tonumber(80000).
               }
            }
            kernel_ctl["import-lib"]("lv/"+data[0]).
         }
      }
   } else {
      print "No parameters specified.".
      //If no parameters given; runs the launch with default values
      setLaunchParams(0, "none").
      launch_param:add("targetApo", 80000).
      kernel_ctl["import-lib"]("lv/"+data[0]).
   }

   kernel_ctl["start"]().
   //Wait until program is finished, and then wait 5 seconds.
   //The following attempts to pass off control of the craft, from the KOS Processor on the Booster, 
   //to the KOS Processor on the payload.
   //For more info, see payload_boot.ks
   wait 1.
   local procs is list().
   list processors in procs.
   for payloadCore in procs {
         payloadCore:connection:sendmessage("launch complete").
   }
   if payloadData {
      core:connection:sendmessage(payloadData). // Send message to myself
      kernel_ctl["import-lib"]("boot/payload").
   } else {
      shutdown.
   }
}
