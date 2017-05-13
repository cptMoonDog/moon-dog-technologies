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
   global OP_FINISHED is 1.
   global OP_CONTINUE is 0.
   global OP_PREVIOUS is -1.

   declare function set_runmode {
      parameter n.
      if n >= -1 and n <= 1
      set runmode to runmode+n.
   }

   set runmode to 0.
   until FALSE {
      //Runmodes
      if runmode > MISSION_PLAN:length {
         set_runmode(MISSION_PLAN[runmode]()).
      }
      else break.

      //Interrupts
      for subroutine in INTERRUPTS {
         subroutine().
      }
   }
}
