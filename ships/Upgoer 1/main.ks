//main.ks primary system for Upgoer 1
//James McConnel
//TODO Get these runmodes coherent.  Call as delegates in a list/lexicon, or globally exported functions?
@LAZYGLOBAL OFF.
runoncepath("knu.ks"). // Use KNU library system

local range_ctl is import_namespace("rangeControl").

// local steering_ctl is import_ns_from("ascent", "steeringControl").
local throttle_ctl is import_ns_from("ascent", "throttleControl").
local staging_ctl  is import_ns_from("ascent", "stagingControl").
local guidance_ctl is import_namespace("maneuver").
local mission_ctl is lexicon().
wait 1.

global SCHEDULE is list().

throttle_ctl["init"](list(
   20000, 1,
   40000, 0.75,
   50000, 0.5,
   60000, 0.3,
   70000, 0.25,
   80000, 0.1
   )).

import_ns_from("ascent", "steeringControl")["init"](lexicon(
   "alt", 80000, 
   "inc", 225, 
   "pOverDeg", 4, 
   "pOverV0", 30, 
   "pOverVf", 150
   )).

SCHEDULE:add({
   return range_ctl["countdown"]().
}).
SCHEDULE:add({
   staging_ctl["launch"]().
   return NEXT_MODE.
}).
SCHEDULE:add({
   staging_ctl["staging"]().
   return throttle_ctl["throttle_monitor"]().
}).
SCHEDULE:add({
   if ship:altitude > 70000 {
      guidance_ctl["add_burn"]("ap", "circularize", 345, 17.73419501).
      return NEXT_MODE.
   }
}).
SCHEDULE:add({
   return guidance_ctl["burn_monitor"]().
}).
wait 1.
print "entering".
set mission_ctl to import_namespace("missionControl").
print "exiting".
//runoncepath("0:/missionControl.ks").
mission_ctl["file_flt_plan"](SCHEDULE).

print "We are GO, for ignition and liftoff...!".
mission_ctl["begin_mission"]().

   
