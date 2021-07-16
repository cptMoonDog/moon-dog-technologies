// "Kernel" for KOS:
//  A system for managing runmodes
//  Run mode (e.g. Current state of ship)
//     Major mission events, reaction to.
//     Runmodes defined as scoped sections exposing a subroutine that does the work.
//     Subroutine returns integer indicating whether to advance, retreat, or loop. 
//  Interrupts
//     Allows for semi-concurrent execution.  Each subroutine is executed continously.
//     Good for reacting to user input.
@LAZYGLOBAL OFF.
global kernel_ctl is lexicon().

global OP_FINISHED is 1.
global OP_CONTINUE is 0.
global OP_PREVIOUS is -1.

global OP_FAIL is "panic".

global MISSION_PLAN is list().
global INTERRUPTS is list().

// Kernel Registers
kernel_ctl:add("status", "").
kernel_ctl:add("output", "").


{
   local runmode is 0.
   local time_share is 0.
   local time_count is 0.

   local next_interrupt is 0.

///Public functions
   declare function run {
      until FALSE {
         //Runmodes
         if runmode < MISSION_PLAN:length {
            set_runmode(MISSION_PLAN[runmode]()).
         } else {
            print "end program.".
            break.
         }

         //Interrupts
         if time_count < time_share {
            set time_count to time_count +1.
         } else {
            set time_count to 0.
            if next_interrupt < INTERRUPTS:length {
               INTERRUPTS[next_interrupt]().
               set next_interrupt to next_interrupt +1.
            } else if next_interrupt = INTERRUPTS:length and INTERRUPTS:length > 0 {
               set next_interrupt to 0.
               INTERRUPTS[next_interrupt]().
            }
         }
      }
      set ship:control:pilotmainthrottle to 0.
   }
   set kernel_ctl["start"] to run@.

///Private functions
   declare function set_runmode {
      parameter n.
      if n = OP_FAIL set runmode to MISSION_PLAN:length+100.
      if n >= -1 and n <= 1 set runmode to runmode+n.
   }
}
