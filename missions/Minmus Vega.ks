@lazyglobal off.

runpath("0:/lib/launch/launchControl.ks").
launch_ctl["init"](
      lexicon(
              //Countdown type and length
              "launchTime",          "window", 
              "countDownLength",      30,
              //Window parameters
              "lan",                  78, 
              "inclination",          6, 
              //Launch options
              "azimuthHemisphere",   "north"),
              //Launch Vehicle
              "Vega 1", "small dog").
