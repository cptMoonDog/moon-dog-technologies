@lazyglobal off.

if not exists("main.ks") {
   runpath("0:/ships/"+ship:name+"/init.ks").
   for f in systemFiles {
      if exists("0:/ships/" + ship:name + "/" + f)
         copypath("0:/ships/" + ship:name + "/" + f, "").
   }
   if not exists("main.ks") {
      print "System Error! Primary system ('main.ks') not found.".
   }else run main.
}else run main.
