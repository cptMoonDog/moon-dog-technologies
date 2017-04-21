@LAZYGLOBAL off.
//runoncepath("knu.ks").

{
   local lib is lexicon().

   local SCHEDULE is list().

   global NEXT_MODE is 1. //Means this section completed successfully advance to next
   global CONTINUE_MODE is 0. // Means situation is nominal continue status quo.
   global PREV_MODE is -1. //Means this section believes retreat is called for
   global ABORT_MODE is 3. //Means situation is not nominal, and it doesn't know what to do.

   local buffer is "".
   local runmode is 0.

   declare function execute {
      until FALSE {
         local status is SCHEDULE[runmode]().
         if status = NEXT_MODE set runmode to runmode + 1.
         else if status = PREV_MODE set runode to runmode - 1.
         else if status = ABORT_MODE on_abort().

         //Interrupts
         if terminalinput:hasChar() {
            set buffer to buffer + terminal:getchar().
         }
      }
   }
   lib:add("begin_mission", execute@).

   declare function set_schedule {
      parameter s.
      set SCHEDULE to s.
   }
   lib:add("file_flt_plan", set_schedule@).

   export_namespace(lib).
}
