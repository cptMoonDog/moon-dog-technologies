@lazyglobal off.
//  Engine configurations defined here, will be available to the maneuver_ctl system.
//  Maneuver_ctl assumes vacuum conditions.
//  Field Values:         name,           isp,  thrust(kN), Minimum Throttle Setting
if not (defined maneuver_ctl)
   global maneuver_ctl is lexicon().

maneuver_ctl["defEngine"]("flintlock",    355,  125,        0.0).//Alias for cheetah
maneuver_ctl["defEngine"]("ant",          315,  2  ,        0.0).
maneuver_ctl["defEngine"]("bobcat",       310,  400,        0.0).
maneuver_ctl["defEngine"]("cheetah",      355,  125,        0.0).
maneuver_ctl["defEngine"]("spark",        320,  20 ,        0.0).
maneuver_ctl["defEngine"]("swivel",       320,  215,        0.1).
maneuver_ctl["defEngine"]("poodle",       350,  250,        0.0).
maneuver_ctl["defEngine"]("bollard",      325,  925,        0.0).
maneuver_ctl["defEngine"]("terrier",      345,  60 ,        0.0).
maneuver_ctl["defEngine"]("beagle",       325,  100,        0.0).
maneuver_ctl["defEngine"]("skipper",      320,  650,        0.0).
maneuver_ctl["defEngine"]("wolfhound",    412,  375,        0.0).
maneuver_ctl["defEngine"]("skiff",        330,  300,        0.0).
maneuver_ctl["defEngine"]("doubleTwitch", 290,  32 ,        0.0).
maneuver_ctl["defEngine"]("doubleThud",   305,  240,        0.0).
maneuver_ctl["defEngine"]("dawn",         4200, 2  ,        0.0).
