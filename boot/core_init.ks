@lazyglobal off.
deletepath("1:/boot").
global dependencies is list().
runpath("0:/lib/core_includes.ks").
if core:tag {
   dependencies:add("0:/missions/"+core:tag+".ks").
}
log "@lazyglobal off." to "1:/temp.ks".
for dep in dependencies {
   local out is dep:split(":")[1]:split(".")[0]+".ksm".
   compile dep to "1:"+out.
   log "runpath("+char(34)+"1:"+out+char(34)+")." to "1:/temp.ks".
}
compile "1:/temp.ks" to "1:/init.ksm".
compile "0:/lib/local_boot.ks" to "1:/boot/local_boot.ksm".
deletepath("1:/temp.ks").
set core:bootfilename to "boot/local_boot.ksm".
reboot.
