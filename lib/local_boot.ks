@lazyglobal off.
if exists("1:/init.ksm") {
   runpath("1:/init.ksm").
   kernel_ctl["start"]().
} else {
   print "Error: Core not initialized for local operation.".
   shutdown.
}
