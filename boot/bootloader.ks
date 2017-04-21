@lazyglobal off.

if exists("1:/stub.ks") {
   runpath("1:/stub.ks").
}else {
   runpath("0:/ships/"+ship:name+"/boot.conf.ks").
   for f in systemFiles {
      if exists("0:/" + f)
         copypath("0:/" + f, "1:/").
   }
   log "run " + kernel + "." to "stub.ks".
   reboot.
}
