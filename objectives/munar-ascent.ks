
@lazyglobal off.
//Reusable sequence template.
//Question: Why not simply have a script file with the contents of the delegate?  Why the extra layers?
//Answer: It seems that the memory area for parameters passed to scripts is always the same.  So, when 
//        a script defines a function to be called later, any additional script called with paramters will
//        clobber the parameter intended for the first one.  To get around this, we create a new scope, to 
//        spawn a new memory space. 
 

{//Create a new namespace.
   add_obj_to_MISSION_PLAN:add("LKO-to-Mun", //Tell the system to add a new delegate to the lexicon of available programs.
      {
         //Initialization code
         local h is 90.
         local p is 90.
         //
         MISSION_PLAN:add({
            if ship:apoapsis < 20000 {
               lock throttle to 1.
               lock steering to heading(h, p).
               if ship:verticalspeed < 100 set p to p + 0.5.
               else set p to p -0.5.
            } else set throttle to 0.

         }).
      }//End of delegate
   ).
}//End of namespace
