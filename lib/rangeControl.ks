@lazyglobal off.
{
   global range_ctl is lexicon().

   local count is 10.
   local lastTime is time:seconds-1.
   declare function do_countdown {
      if count > -1 and time:seconds-lastTime > 1 {
         hudtext(count+"...", 1, 2, 20, white, false).
         set count to count - 1.
         set lastTime to time:seconds.
         return OP_CONTINUE.
      } else if count < 0 {
         return OP_FINISHED.
      } else return OP_CONTINUE.
   }
   range_ctl:add("countdown", do_countdown@).
}
