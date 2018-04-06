@lazyglobal off.
//Reusable sequence template.
//Question: Why not simply have a script file with the contents of the delegate?  Why the extra layers?
//Answer: It seems that the memory area for parameters passed to scripts is always the same.  So, when 
//        a script defines a function to be called later, any additional script called with paramters will
//        clobber the parameter intended for the first one.  To get around this, we create a new scope, to 
//        spawn a new memory space. 
 

{//Create a new namespace.
   available_objectives:add("munar-ascent", //Tell the system to add a new delegate to the lexicon of available programs.
      {
         //Initialization code
         runpath("0:/lib/maneuver_ctl.ks").
         local start is 0.
         local h is 90.
         local p is 90.
         local lastAlt is 0.
         local lastTime is time:seconds.
         //
         MISSION_PLAN:add({
            if start=0 set start to time:seconds.
            if time:seconds < start + 10 return OP_CONTINUE.
            if ship:apoapsis < 20000 {
               lock throttle to 1.
               lock steering to heading(h, p).
               if ship:altitude < 8500 {
                  local dAlt is (alt:radar-lastAlt)/(time:seconds-lastTime).
                  if dAlt < 0 or ship:verticalspeed < 10 set p to min(90, p + 0.5).
                  else set p to max(0, p - 0.5).
               } else if ship:verticalspeed < 10 and ship:periapsis < 0 set p to min(90, p + 0.5). 
               else set p to max(0, p - 0.5).
               set lastAlt to alt:radar.
               return OP_CONTINUE.
            } else {
               set throttle to 0.
               set start to 0.
               return OP_FINISHED.
            }
         }).
         MISSION_PLAN:add({
            maneuver_ctl["add_burn"]("prograde", "terrier", "ap", "circularize").
            return OP_FINISHED.
         }).
         MISSION_PLAN:add(maneuver_ctl["burn_monitor"]).
      }//End of delegate
   ).
}//End of namespace
