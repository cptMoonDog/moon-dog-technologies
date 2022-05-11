@lazyglobal off.
if exists("0:/missions/"+core:tag+".ks") {
   runpath("0:/missions/"+core:tag+".ks").
   if defined DEPENDENCIES {
      compile "0:/lib/core/kernel.ks" to "1:/kernel.ksm".
      for package in DEPENDENCIES {
         compile "0:/"+package+".ks" to "1:/"+package+".ksm".
      }
   }
   compile "0:/missions/"+core:tag+".ks" to "1:/boot/firmware.ksm".
   set core:bootfilename to "/boot/firmware".
}
