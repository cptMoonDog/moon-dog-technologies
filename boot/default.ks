print "booting...".
wait 3.
copypath("0:/ships/"+ship:name, "").
//copypath("0:/ships/"+ship:name+".deorbit.ks", "").
copypath("0:/maneuver.ks", "").
if ship:periapsis > 70000 {
   hudtext("Deorbiting...", 1, 2, 20, white, false).
   print "Deorbiting...".
   runpath(ship:name+".deorbit.ks").
} else {
   print "System ready.".
   print "GKerman@KSC:>launch".
   print "Are you sure?  You still have a chance to change your mind.".
   print "  Press Y to launch.".
   wait until terminal:input:haschar().
   set c to terminal:input:getchar().
   if c = "y" or c = "Y" runpath(ship:name + ".ks").
   else print "Good idea! Always better safe than sorry!".
}
