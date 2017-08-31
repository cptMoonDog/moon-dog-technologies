@lazyglobal off.
installToShip("lib/general.ks").
{
   global ascent_ctl is lexicon().

   ///Initialises the library.
   declare function passthrough {
      parameter obt.
      parameter ast.
      parameter th.

      ascent_ctl["init_steering"](obt, ast).
      ascent_ctl["init_throttle"](th, "apo").

      kernel_ctl["add_step"](ascent_ctl["launch"]).
      kernel_ctl["add_step"](ascent_ctl["ascent_monitor"]).
   }
   ascent_ctl:add("init", passthrough@).

   local count is 0.
   ///The ascent program itself.
   declare function ascentProgram {
      print "." at(count, 22).
      set count to count+1.
      ascent_ctl["staging"](true, true).
      return ascent_ctl["throttle_monitor"]().
   }
   ascent_ctl:add("ascent_monitor", ascentProgram@).
}
