@lazyglobal off.

if exists("1:/stub.ks") {
   runpath("1:/stub.ks").
}else {
   runpath("0:/ships/"+ship:name+"/boot.conf.ks").
   for f in systemFiles {
      if core:volume:freespace < 10 {
         print "Copy failure: NOT ENOUGH FREESPACE!!!!!".
         print core:volume:freespace.
         print "Upgrade computer core, or fire your software developers,".
         print "all those bits can't be that important.".
         break.
      }
      if exists("0:/" + f) {
         copypath("0:/" + f, "1:/").
         log f to "log.txt".
      }
   }
   local lastCopyPath is systemFiles[systemFiles:length-1]:split("/").
   local lastCopyName is lastCopyPath[lastCopyPath:length-1].
   if exists("1:/"+lastCopyName) {
      log "run " + kernel + "." to "stub.ks".
      wait 1.
      reboot.
   }
}
