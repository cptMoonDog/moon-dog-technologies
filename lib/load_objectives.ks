@lazyglobal off.
declare parameter objectives is list().
declare global add_obj_to_MISSION_PLAN is lexicon().
for x in objectives {
   runpath("0:/programs/"+x+".ks").
}
