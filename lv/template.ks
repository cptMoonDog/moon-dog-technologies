@lazyglobal off.
//This is a standard Launch Vehicle parameter file.
//This holds the information necessary to customize the flight profile for your lifter.

declare parameter inclination is 0.
declare parameter lan is "none".
declare parameter launchToAlt is 80000.

{
   /////////////////// Standard Boiler plate /////////////////////
   // You probably don't want to change this stuff.

   //Load the launch system into memory
   runpath("0:/lib/launch/launch_ctl.ks").

   /////////////////////////// Keplerian Orbital Parameters ////////////////////////
   //The default 0 is equatorial
   launch_param:add("inclination",          inclination).
   
   //If orbital parameters are not specified, the LAN does not need to be passed. 
   if lan="none" {             
      launch_param:add("launchTime",        "now"). 
   } else if lan:istype("Scalar") {
      launch_param:add("launchTime",        "window"). 
      launch_param:add("lan",               lan).
   }
   /////////////////// End Standard Boiler plate /////////////////////

   ////////////////////////// Launch Options /////////////////////////////////////
   //Any inclination can be achieved twice a day.
   // If "north" is specified, rocket will be launched at the Ascending Node.
   // Launch azimuth will be on a northerly heading.
   // If "south" is specified, rocket will be launched at the Descending Node.
   // Launch azimuth will be on a southerly heading.
   // If "all" or "any" is specified, rocket will be launched at the nearest Node.
   // Launch azimuth will be which ever is necessary.
   launch_param:add("azimuthHemisphere",   "all").

   //Fudge factor  
   // Why this is needed: This script is capable of launching into inclined orbits, 
   // however the inclination is not achieved instantly upon launch, which means 
   // the Longitude of the Ascending node will be off slightly (in the direction of rotation).
   // To compensate this factor will activate the launch sequence this number of seconds prior to the 
   // calculated launch time. It is called Time of Flight, because the launch window lead time 
   // should be the same as the amount of time it takes to achieve the proper inclination, which 
   // will also be about the same as the amount of time needed to achieve orbital velocity.  
   // For the record, this will vary with the inclination.
   launch_param:add("timeOfFlight",         180+2*inclination).

   ///////////////////////////// Gravity turn parameters ////////////////////////////////
   launch_param:add("pOverDeg",             5).  // Pitchover magnitude in degrees
   launch_param:add("pOverV0",              50). // Vertical speed at which to start pitchover                        
   launch_param:add("pOverVf",              150).// Vertical speed at which to handoff steering to prograde follower.

   //Throttle program parameters
   // There are three possible values for launch_param["throttleProgramType"]:

   //    1. "setpoint" maintains a set value for the launch_param["throttleReferenceVar"] using a PID.
   //          In this case, launch_param["throttleProfile"] is a list of three items:
   //             [apo at which this function should take control], [apo of final orbit], and [setpoint for PID]

   //    2. "function" returns the value of a custom function defined in: config/throttle_functions.ks
   //          In this case, launch_param["throttleProfile"] is a list of two or three items:
   //             [apo at which this function should take control], [apo of final orbit], and [function parameter (optional)]

   //    3. "table" sets the throttle from a table of values versus "throttleReferenceVar", and using a function to smooth the output.
   //          In this case, launch_param["throttleProfile"] is a list (yes, list), of [ReferenceVar], [throttle] pairs.
   //          Note: The throttle setting in a row of the table is the value for the throttle up to, NOT following the reference value.  
   //          Note 2: This is the best method if you want the "perfect" ascent.
   //                  It can be fully customized for your lift vehicle, no other method can account for the peculiarities of one specific rocket.

   //   Note: For comparison, MechJeb defines a curve versus altitude and forces the rocket to follow it.
   //         The Gravity Turn mod uses a "Zero-Lift" maneuver (Always pointing prograde), and adjusts the throttle to maintain a constant eta:apoapsis.
   //         Any ascent using this system will be a "Zero-Lift" maneuver (AKA Gravity Turn). The various methods are different ways to manage the throttle during the ascent.
   
   //Examples:

     // This is a decent general ascent
   launch_param:add("throttleProgramType", "setpoint"). 
   launch_param:add("throttleReferenceVar", "etaAPO"). 
   launch_param:add("throttleProfile", list( 
                                            2000, //Apo to Activate function, max prior
                                            launchToAlt, //Apo to Deactivate function 
                                            45)).  //Setpoint

      // For some reason, constant TWR ascents are popular recently.  It's not a great idea (<-- My opinion, your mileage may vary.), but here ya go!
      // You can make your own functions too!
   //launch_param:add("throttleProgramType", "function").
   //launch_param:add("throttleFunction", "constantTWR").
   //launch_param:add("throttleProfile", list( 
   //                                          2000, //Apo to Activate function, max prior
   //                                          launchToAlt //Apo to Deactivate function 
   //                                          , 1.5 //Functions can take an optional parameter, in this case the TWR to maintain is 1.5
   //                                          )).

     // Table based methods are the way to go, if you want exactly the right ascent for your specific rocket.
     // It can't be wrong if NASA uses it, right?
     // This table is using Mission Elapsed Time, like the Saturn V used.
   //launch_param:add("throttleProgramType", "table").
   //launch_param:add("throttleReferenceVar", "MET"). 
   //launch_param:add("throttleProfile", list( 
   //                                          30, 1,
   //                                          60, 0.5,
   //                                          120, 0.5,
   //                                          200, 0.25,
   //                                          250, 0.1
   //                                          )).

   //Upper stage
   // This tells the system which upper stage is installed.
   // This information is used primarily by the circularization burn.
   launch_param:add("upperstage", "wolfhound").

   //The system will display a countdown of this length before any launch.
   launch_param:add("countDownLength",      20).

   
   //Initialize the launch system.
   // Parameter 1: Activate AG1 at 60km
   // Parameter 2: Activate AG2 at 65km
   launch_ctl["init"](TRUE, TRUE).

   //Add a launch to LKO routine to the MISSIONPLAN
   launch_ctl["addLaunchToMissionPlan"]().
}

