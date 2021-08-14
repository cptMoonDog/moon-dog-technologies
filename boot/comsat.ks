@lazyglobal off.

if ship:status="PRELAUNCH" {
   compile "0:/lib/core/kernel.ks" to "1:/kernel.ksm".
   compile "0:/programs/orient-to-max-solar.ks" to "1:/orient.ksm".
   if core:tag {
      local data is core:tag:split(":").
      if data:length > 1 {
         local mission is data[1].
         if exists("0:/missions/"+mission:trim+".ks") compile "0:/missions/"+mission:trim+".ks" to "1:/mission.ksm".
      }
   }
   local procs is list().
   until procs:length = 1{
      list processors in procs.
   }
   set ship:name to core:tag.
   set kuniverse:activevessel to ship.
   local eng is list().
   list engines in eng.
   if eng:length = 1 {
      runpath("0:/runprogram.ks", "circularize-at-ap", list("ant")).
   }
   set kuniverse:activevessel to vessel("Comsat Deployment").
} else if ship:status="ORBITING" {
   //Post Deployment code
   if ship:orbit:eccentricity > 0.8 {
      local procs is list().
      until procs:length = 1{
         list processors in procs.
      }
      set ship:name to core:tag.
      set kuniverse:activevessel to ship.
      local eng is list().
      list engines in eng.
      if eng:length = 1 {
         runpath("0:/runprogram.ks", "circularize-at-ap", list("ant")).
      }
      set kuniverse:activevessel to vessel("Comsat Deployment").
   } else {
      //On orbit station keeping
      runpath("1:/kernel.ksm").
      runpath("1:/orient.ksm").
      available_programs["orient-to-max-solar"]().
      if exists("1:/mission.ksm") runpath("1:/mission.ksm").
      kernel_ctl["start"]().
   }
}
