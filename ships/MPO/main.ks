@lazyglobal off.
//Remote 
runpath("0:/lib/rangeControl.ks").
//Local
runpath("ascent/ascentControl.ks").
runpath("guidanceControl.ks").
runpath("kernel.ks").
{
   local hemisphere is "north".
   local inclination is 0.
   range_ctl["init"](10).
   ascent_ctl["init"](
      lexicon( //Orbit parameters
         "altitude", 80000, 
         "inclination", 0 
      ), 
      lexicon( //Ascent Parameters
         "hemisphere", "north",
         "pOverDeg", 5, 
         "pOverV0", 20, 
         "pOverVf", 150
      ),
      list( //Throttle lookup table
         10000, 1,
         60000, 1,
         70000, 0.5,
         80000, 0.15
   )).
   guidance_ctl["init_orbit_insertion"]().

   kernel_ctl["start"]().
} 
