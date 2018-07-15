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

{
   local runmode is 0.

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
         for subroutine in INTERRUPTS {
            subroutine().
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
