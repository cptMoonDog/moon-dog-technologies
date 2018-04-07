@lazyglobal off.
declare parameter objectives is list().
declare global available_objectives is lexicon().
for x in objectives {
   runpath("0:/objectives/"+x+".ks").
}
