@lazyglobal off.
//Reusable sequence template.
//Question: Why not simply have a script file with the contents of the delegate?  Why the extra layers?
//Answer: It seems that the memory area for parameters passed to scripts is always the same.  So, when 
//        a script defines a function to be called later, any additional script called with paramters will
//        clobber the parameter intended for the first one.  To get around this, we create a new scope, to 
//        spawn a new memory space. 
 

{//Create a new namespace.
   add_obj_to_MISSION_PLAN:add("munar-ascent", //Tell the system to add a new delegate to the lexicon of available programs.
      {
         print vang(up:forevector, ship:body:up:forevector) at(0, 10).
      }).
}

