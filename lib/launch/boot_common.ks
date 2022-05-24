@lazyglobal off.
// This script contains the section common to the Launch Vehicle(lv_boot.ks) and Single Core boot scripts. 
// It exists SOLELY to reduce repetition and to make maintenance easier.

   //IMPORTANT:
   // 1. In the VAB, set the nameTag of this core to the name of lifter definition file in the lv directory.
   // 2. For inclined orbits, append to the nameTag: ", [inclination], [LAN]" 
   // For example, to use the "Spud Atlas" launch vehicle and launch into an orbit coplanar with Minmus,
   // give the core on the launch vehicle the nameTag: "Spud Atlas, 6, 78".
   // Or, just set the nameTag to "Spud Atlas, Minmus"
   
   //local Lparameters is "".
   //if core:tag set Lparameters to core:tag.
   //else if exists("0:/launchparameters.txt") {
   //   local f is open("0:/launchparameters.txt").
   //   local i is f:itsrator.
   //   until i:atend {
   //      if i:value:tostring:trim:tolower:startswith("//launch") {
   //         i:next.
   //         set Lparameters to i:value.
   //      } else if i:value:tostring:trim:tolower:startswith("//payload") {
   //         i:next.
   //         set Pparameters to i:value.
   //      }
   //   }
   //}
if core:tag {  
   runoncepath("0:/lib/core/kernel.ks").
   runoncepath("0:/lib/launch/launch_ctl.ks").
   local data is core:tag:split(",").
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
            runpath("0:/lv/"+data[0]+".ks").
         } else {
            set target to data[1]:trim.
            if target:body = ship:body { /// Targets in orbit of Origin Body ///
               print target:orbit:inclination at(0, 9).
               if target:orbit:inclination >= 1 or abs(ship:latitude) >= 1 setLaunchParams(target:orbit:inclination, target:orbit:lan).
               else {
                  launch_param:add("orbitType", "rendezvous").
                  setLaunchParams(0, "none").
               }
               runpath("0:/lv/"+data[0]+".ks").
            } else { /// Interplanetary Targets ///
               parameters given; runs the launch with default values
      setLaunchParams(0, "none").
      launch_param:add("targetApo", 80000).
      runpath("0:/lv/"+data[0]+".ks").
      // just launch equatorial
               //runpath("0:/lib/physics.ks").
               //local ttWindow is phys_lib["etaPhaseAngle"](body("Kerbin"), target).
               //print ttWindow.
               //TODO make this work. Update: Not relevant ipt should not be handled by this stage 
               runpath("0:/lv/"+data[0]+".ks").
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
         runpath("0:/lv/"+data[0]+".ks").
      }
   } else {
      //If no parameters given; runs the launch with default values
      setLaunchParams(0, "none").
      launch_param:add("targetApo", 80000).
      runpath("0:/lv/"+data[0]+".ks").
   }
}// else if exists("0:/lv/"+ship:name+".ks") {
   //If the nameTag on the core is not used, attempt to find a script with the ship:name instead
  // setLaunchParams(target:orbit:inclination, target:orbit:lan).
   //runpath("0:/lv/"+ship:name+".ks").
//}

declare local function setLaunchParams {
   parameter inclination is 0.
   parameter lan is "none".
   
   launch_param:add("inclination", inclination).
   if lan = -1 set lan to "none".
   launch_param:add("lan", lan).
   
   if launch_param["lan"]="none" or launch_param["inclination"] = 0 or launch_param["inclination"] = 180 {             
      launch_param:add("launchTime",        "now"). 
   } else if lan:istype("Scalar") {
      launch_param:add("launchTime",        "window"). 
   }
}
