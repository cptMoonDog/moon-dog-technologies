@lazyglobal off.
if not exists("1:/lib/core/kernel.ksm") 
   compile "0:/lib/core/kernel.ks" to "1:/lib/core/kernel.ksm".
runpath("1:/lib/core/kernel.ksm", true).
