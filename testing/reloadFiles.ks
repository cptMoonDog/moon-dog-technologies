runpath("0:/ships/"+ship:name+"/init.ks").
for f in systemFiles {
   if exists("0:/ships/" + ship:name + "/" + f)
      copypath("0:/ships/" + ship:name + "/" + f, "").
}

