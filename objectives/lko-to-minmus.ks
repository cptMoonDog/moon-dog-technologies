@lazyglobal off.
//Reusable sequence template.
//Question: Why not simply have a script file with the contents of the delegate?  Why the extra layers?
//Answer: It seems that the memory area for parameters passed to scripts is always the same.  So, when 
//        a script defines a function to be called later, any additional script called with parameters will
//        clobber the parameter intended for the first one.  To get around this, we create a new scope, to 
//        spawn a new memory space. 
declare parameter ename is "". 
if not (defined available_objectives) declare global available_objectives is lexicon().
if not (defined kernel_ctl) runpath("0:/lib/core/kernel.ks"). 

{//Create a new namespace.
   set available_objectives["lko-to-minmus"] to {
      //One time initialization code.
      declare parameter engineName.
      if not (defined transfer_ctl) runpath("0:/lib/transfer_ctl.ks").
      if not (defined maneuver_ctl) runpath("0:/lib/maneuver_ctl.ks").
      print "WARNING minmus maneuver assumes ship is in a coplanar orbit.".

      //Implement the instructions which will be added to the end of the missions sequence.   
      MISSION_PLAN:add({
         if ship:maxthrust > 1.01*maneuver_ctl["engineStat"](engineName, "thrust") {
            stage. 
         }
         wait 5.
         set target to body("Minmus").
         local mnvr is node(transfer_ctl["etaPhaseAngle"]()+time:seconds, 0,0, transfer_ctl["dv"]("Kerbin", "Minmus")).
         add(mnvr).
         until false {
            if mnvr:orbit:hasnextpatch and mnvr:orbit:nextpatch:body:name = "Minmus" and mnvr:orbit:nextpatch:periapsis > body("Minmus"):radius+5000 {
               break.
            }else if mnvr:orbit:hasnextpatch and mnvr:orbit:nextpatch:body:name = "Minmus" and mnvr:orbit:nextpatch:periapsis < body("Minmus"):radius+5000 {
               print "adjusting pe" at(0, 1).
               set mnvr:prograde to mnvr:prograde + 0.01.
            }else if mnvr:orbit:apoapsis > body("Minmus"):altitude {
               print "adjusting ap" at(0, 1).
               set mnvr:prograde to mnvr:prograde - 0.01.
            }else {
               break. 
            }
         }
         maneuver_ctl["add_burn"]("node", engineName, "node", mnvr:deltav:mag).
         return OP_FINISHED.
      }).
      MISSION_PLAN:add(maneuver_ctl["burn_monitor"]).
   }. //End of delegate
} //End namespace


if ename {
   available_objectives["lko-to-minmus"]("beagle").
   kernel_ctl["start"]().
} else {
   print "no ename".
}