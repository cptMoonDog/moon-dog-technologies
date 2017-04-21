{
   local count is 10.
   local lastTime is time:seconds-1.
   declare function do_countdown {
      if count >= 0 and time:seconds-lastTime >= 1 {
         hudtext(count+"...", 1, 2, 20, white, false).
         set count to count -1.
         set lastTime to time:seconds.
         wait 0.0001.
         return CONTINUE_MODE.
      }else if time:seconds-lastTime > 1 {
         return EXIT_MODE.
      }
   }
   global countdown is do_countdown@.
}

