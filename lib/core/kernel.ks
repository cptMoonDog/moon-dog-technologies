//  kOS scheduler:
//  Run mode (e.g. Current state of ship)
//     Major mission events, reaction to.
//     Runmodes defined as scoped sections exposing a subroutine that does the work.
//     Subroutine returns boolean indicating whether or not it is finished, outer loop will then move to next mode.
//  Interrupts
//     Staging
//     User input
//  Ex:
//Mon Jun 19 21:37:58 PDT 2017
@LAZYGLOBAL OFF.
global kernel_ctl is lexicon().

global OP_FINISHED is 1.
global OP_CONTINUE is 0.
global OP_PREVIOUS is -1.

global OP_FAIL is 0.5.

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
         } else break.

         //Interrupts
         for subroutine in INTERRUPTS {
            subroutine().
         }
      }
      set ship:control:pilotmainthrottle to 0.
   }
   kernel_ctl:add("start", run@).

///Private functions
   declare function set_runmode {
      parameter n.
      if n = OP_FAIL set runmode to MISSION_PLAN:length+1.
      if n >= -1 and n <= 1 set runmode to runmode+n.
   }
}
