@lazyglobal off.
//Remote 
linkRemoteSystem("rangeControl").
//Local
<<<<<<< HEAD
runpath("ascent/ascentControl.ks").
runpath("guidanceControl.ks").
runpath("kernel.ks").
{
=======
installToShip("ascentControl").
installToShip("guidanceControl").
>>>>>>> 32d18d119b8cc53f9935eaad1cedcde4df15a922
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