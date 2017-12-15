@lazyglobal off.
declare parameter objectives is list().
declare global program_ctl is lexicon().
for x in objectives {
   runpath("0:/programs/"+x+".ks").
}
