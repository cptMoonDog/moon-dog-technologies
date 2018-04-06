@lazyglobal off.
declare parameter objectives is list().
declare global available_objectives is lexicon().
declare global function getObjectiveSetupFunction {
   declare parameter name.
   return available_objectives[name].
}
for x in objectives {
   runpath("0:/objectives/"+x+".ks").
}
