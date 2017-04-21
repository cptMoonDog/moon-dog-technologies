// boot process:
// bios (KOS) loads bootloader.ks
// bootloader finds the archive for the rocket on the mainframe, and copies over the files listed in boot.conf.ks
// bootloader writes a file called stub.ks which contains a run command for the kernel executable listed in boot.conf.ks
// bootloader reboots, and this time runs stub.ks
// 
// This "kernel" allows "processes" to be added or removed.
// 
// add modal takes a list of delegates and runs them in order and advances when the delegates return value indicates it is done.
// The kernel should allow for multiple processes.
// Including terminal input.

global PROC_FINISHED is 10.
global PROC_CONTINUE is 11.
{
   local processes is lexicon().
   local EXIT is TRUE.
   declare function primary_kernel {
      until EXIT {
         local current is processes:keys:iterator.
         current:reset().
         until not current:next() {
            if processes[current:value]() = PROC_FINISHED {
               processes:remove(current:value).
               print "process removed".
            }
            wait 0.00001.
         }
      }
   }
   global kernel_add_proc is {
      parameter n.
      parameter p.
      processes:add(n, p).
   }.
     
   global kernel_remove_proc is {
      parameter n.
      processes:remove(n).
   }.
   global start_kernel is {
      set EXIT to FALSE.
      primary_kernel().
   }.
   global stop_kernel is {
      set EXIT to TRUE.
   }.
   global kernel_add_modal_proc is {
      parameter s.
      set schedule to s.
      processes:add("main", runmode@).
   }.

   global NEXT_MODE is 2. //Means this section completed successfully advance to next
   global CONTINUE_MODE is 3. // Means situation is nominal continue status quo.
   global PREV_MODE is 4. //Means this section believes retreat is called for
   global ABORT_MODE is 5. //Means situation is not nominal, and it doesn't know what to do.
   
   local mode is 0.
   local schedule is list().
   declare function runmode {
      print "mode: " + mode at(0, 21).
      if schedule[mode]() = NEXT_MODE {
         set mode to mode + 1.
         return PROC_CONTINUE.
      } 
      if mode > schedule:length return PROC_FINISHED.
      return PROC_CONTINUE.
   }

}
