@lazyglobal off.
// This script contains the section common to the Launch Vehicle(lv_boot.ks) and Single Core boot scripts. 
// It exists SOLELY to reduce repetition and to make maintenance easier.

   //IMPORTANT:
   // 1. In the VAB, set the nameTag of this core to the name of lifter definition file in the lv directory.
   // 2. For inclined orbits, append to the nameTag: ", [inclination], [LAN]" 
   // For example, to use the "Spud Atlas" launch vehicle and launch into an orbit coplanar with Minmus,
   // give the core on the launch vehicle the nameTag: "Spud Atlas, 6, 78".
   // Or, just set the nameTag to "Spud Atlas, Minmus"
runOnVolume("0:/lib/launch/launch_ctl.ks").
if not(exists("0:/lv/"+bootparams["lv"]+".ks")) {
   print "Fatal error: No Launch Vehicle definition file".
   shutdown.
}
// Target handling
if bootparams:haskey("target") {
   print "target: "+ bootparams["target"].
   if bootparams["target"] = "Polar" { /// Dummy Targets ///
      setLaunchParams(90, 0).
      runOnVolume("0:/lv/"+bootparams["lv"]+".ks").
   } else {
      set target to bootparams["target"].
      if target:body = ship:body { /// Targets in orbit of Origin Body ///
         setLaunchParams(target:orbit:inclination, target:orbit:lan).
         runOnVolume("0:/lv/"+bootparams["lv"]+".ks").
      } else { /// Interplanetary Targets ///
         runOnVolume("0:/lib/physics.ks").
         local ttWindow is phys_lib["etaPhaseAngle"](body("Kerbin"), target).
         print ttWindow.
         //TODO make this work
         runOnVolume("0:/lv/"+bootparams["lv"]+".ks").
      }
   }
} else { /// Defined orbit, 
   setLaunchParams(bootparams["inclination"], bootparams["LAN"]).
   if bootparams:haskey("OrbitType") and bootparams["OrbitType"] = "transfer"  {
      launch_param:add("orbitType", "transfer").  //If transfer is selected, circularization is not performed and payload is expected to takeover.
      launch_param:add("toPeriapsis", bootparams["toPeriapsis"]).
   }
   launch_param:add("orbit altitude", bootparams["launchToAlt"]).
   runOnVolume("0:/lv/"+bootparams["lv"]+".ks").
}

declare local function setLaunchParams {
   parameter inclination is 0.
   parameter lan is "none".
   
   launch_param:add("inclination", inclination).
   if lan = -1 set lan to "none".
   launch_param:add("lan", lan).
   
   if launch_param["lan"]="none" or launch_param["inclination"] = 0 or launch_param["inclination"] = 180 {             
      launch_param:add("launchTime",        "now"). 
   } else if launch_param["lan"]:istype("Scalar") {
      launch_param:add("launchTime",        "window"). 
   }
}
