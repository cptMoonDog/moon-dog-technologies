@lazyglobal off.
{
   global ascent_ctl is lexicon().

   declare function passthrough {
      parameter obt.
      parameter ast.
      parameter th.

      runpath("ascent/throttleControl.ks", th).
      runpath("ascent/steeringControl.ks", obt, ast).
      runpath("ascent/stagingControl.ks").

      kernel_ctl["add_step"](ascent_ctl["launch"]).
      kernel_ctl["add_step"](ascent_ctl["ascent_monitor"]()).
  }
   ascent_ctl:add("init", passthrough@).

   declare function ascentProgram {
      ascent_ctl["staging"](true, true).
      return ascent_ctl["throttle_monitor"]().
   }
   ascent_ctl:add("ascent_monitor", ascentProgram@).
}
