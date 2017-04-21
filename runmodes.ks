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
global EXIT_MODE is 1.
global CONTINUE_MODE is 0.

global RUNMODES is lexicon().

run once countdown.
run once throttleControl.
run once steeringControl.
run once stagingControl.



declare function next_runmode {
   set runmode t runmode+1.
}

set runmode to 1.
until FALSE {
   //Runmodes
   if runmode = 1 {
      if RUNMODES["countdown"]() = EXIT_MODE next_runmode().
   }else if runmode = 2 {
      if do_throttleCheck() = EXIT_MODE next_runmode().
   }


   //Interupts
   if terminalinput:hasChar() {
      set buffer to buffer + terminal:getchar().
   }
}
   
