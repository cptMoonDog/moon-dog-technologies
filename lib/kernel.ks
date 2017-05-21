//  kOS scheduler:
//  Run mode (e.g. Current state of ship)
//     Major mission events, reaction to.
//     Runmodes defined as scoped sections exposing a subroutine that does the work.
//     Subroutine returns boolean indicating whether or not it is finished, outer loop will then move to next mode.
//  Interrupts
//     Staging
//     User input
//  Ex:
@LAZYGLOBAL OFF.
{
   print "enter kernel for init.".
   global OP_FINISHED is 1.
   global OP_CONTINUE is 0.
   global OP_PREVIOUS is -1.

   global kernel_ctl is lexicon().

   declare function set_runmode {
      parameter n.
      if n >= -1 and n <= 1
      set runmode to runmode+n.
   }

   local runmode is 0.
   declare function run {
      parameter missionPlan is list().
      parameter interrupts is list().
      until FALSE {
         //Runmodes
         if runmode < missionPlan:length {
            set_runmode(missionPlan[runmode]()).
         }
         else break.

         //Interrupts
         for subroutine in INTERRUPTS {
            subroutine().
         }
      }
   }
   kernel_ctl:add("start", run@).
}
