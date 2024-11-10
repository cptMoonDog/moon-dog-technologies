@lazyglobal off.
// Will run the script in 0:/extra given by the core tag on boot.
if ship:status = "PRELAUNCH" and core:tag {
   if exists("0:/extra/"+core:tag+".ks") runpath("0:/extra/"+core:tag+".ks").
}
