@lazyglobal off.
if ship:status = "ORBITING" and ship:orbit:eccentricity < 0.8 {
   local procs is list().
   until procs:length = 1{
      list processors in procs.
   }

   runpath("0:/runprogram.k", "circularize-at-ap", list("ant")).
} else if ship:status = "ORBITING" {
   //TODO orient panels to sun.
}

