@lazyglobal off.
//This is a standard Launch Vehicle parameter file.
//This holds the information necessary to customize the flight profile for your lifter.

if not(launch_param:haskey("targetApo")) launch_param:add("targetApo", 80000).
{
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
   launch_param:add("timeOfFlight",         180+2*launch_param["inclination"]).

   ///////////////////////////// Gravity turn parameters ////////////////////////////////
   local emptyMass is 81.153. //tons
   /// Pitchover magnitude in degrees, the heavier it is, the less the pitch
   /// TWR might have something to say about this... question is, how to integrate it, no engines are active, so cannot poll availablethrust
   //launch_param:add("pOverDeg",             (12-(1-ship:mass/emptyMass)*10)). // Give 0 at double empty mass. About 8.5 for SaltyDog CRS
   launch_param:add("pOverDeg",             8).
   launch_param:add("pOverV0",              50). // Vertical speed at which to start pitchover                        
   launch_param:add("pOverVf",              180).// Vertical speed at which to handoff steering to prograde follower.

   //Steering Program
   // Available by default: "LTGT": Pitchover follows a linear tangent curve, but during main body of the ascent follows ship:srfprograde.  Probably the most efficient.
   //                       "atmospheric": Legacy code.  Initiates a gravity turn using the "pOver" parameters above, and follows ship:srfprograde to altitude.  Not bad, but a little adhoc.
   //                       "linearTangent": Follows a linear tangent curve.  NOT A GRAVITY TURN.  DOES NOT follow ship:srfprograde.
   launch_param:add("steeringProgram", "atmospheric").
   //launch_param:add("steeringProgram", "linearTangent").
   //launch_param:add("LTShape", 3.25).
   //launch_param:add("steeringProgram", "LTGT").
   

   //Throttle program parameters
   // There are three possible values for launch_param["throttleProgramType"]:

   //    1. "setpoint" maintains a set value for the launch_param["throttleReferenceVar"] using a PID.
   //          In this case, launch_param["throttleProfile"] is a list of three items:
   //             [apo at which this function should take control], [apo of final orbit], and [setpoint for PID]
   //          Possible values for "throttleReferenceVar": "etaApo": ETA:apoapsis
   //                                                      "flightPathAngle": The angle the facing vector of your rocket makes with vertical.  Intended for use use with a linear tangent setpoint.
   //         1.A. Variable setpoints: 
   //              The system expects a scalar quantity as the third item in "throttleProfile", but if instead you use "linearTangent" 
   //              it will continuously update the value of the setpoint to phys_lib["linearTan"]

   //    2. "function" returns the value of a custom function defined in: config/throttle_functions.ks
   //          In this case, launch_param["throttleProfile"] is a list of two or three items:
   //             [apo at which this function should take control], [apo of final orbit], and [function parameter (optional)]

   //    3. "table" sets the throttle from a table of values versus "throttleReferenceVar", and using a function to smooth the output.
   //          In this case, launch_param["throttleProfile"] is a list (yes, list), of [ReferenceVar], [throttle] pairs.
   //          Note: The throttle setting in a row of the table is the value for the throttle up to, NOT following the reference value.  
   //          Note 2: This is the best method if you want the "perfect" ascent.
   //                  It can be fully customized for your lift vehicle, no other method can account for the peculiarities of one specific rocket.
   //          Possible values for "throttleReferenceVar": "etaAPO": ETA:apoapsis
   //                                                      "MET": Mission elapsed time.
   //                                                       

   //   Note: For comparison, MechJeb defines a curve versus altitude and forces the rocket to follow it.
   //         The Gravity Turn mod uses a "Zero-Lift" maneuver (Always pointing prograde), and adjusts the throttle to maintain a constant eta:apoapsis.
   //         This system is mostly designed with Gravity turns in mind, although linear tangent steering is now an option.  
   //   Note 2: See lib/launch/throttle_ctl.ks to add more "throttleReferenceVar"s
   
   //Examples:

     // Manages the throttle to cause the ship:prograde vector to follow a linear tangent curve on ascent
   //launch_param:add("throttleProgramType", "setpoint"). 
   //launch_param:add("throttleReferenceVar", "flightPathAngle"). 
   //launch_param:add("throttleProfile", list( 
   //                                         1000, //Apo to Activate function, max prior
   //                                         launch_param["targetApo"], //Apo to Deactivate function 
   //                                         "linearTangent")).  //Setpoint
     // This is a decent general ascent
   //launch_param:add("throttleProgramType", "setpoint"). 
   //launch_param:add("throttleReferenceVar", "etaApo"). 
   //launch_param:add("throttleProfile", list( 
   //                                         1000, //Apo to Activate function, max prior
   //                                         launch_param["targetApo"], //Apo to Deactivate function 
   //                                         50)).  //Setpoint

      // You can make your own functions too! See configs/launch/throttle-functions.ks
      // For some reason, constant TWR ascents are popular recently.  It's not a great idea (<-- My opinion, your mileage may vary.), but here ya go!
   //launch_param:add("throttleProgramType", "function").
   //launch_param:add("throttleFunction", "constantTWR").
   //launch_param:add("throttleProfile", list( 
   //                                          2000, //Apo to Activate function, max prior
   //                                          launch_param["targetApo"] //Apo to Deactivate function 
   //                                          , 1.5 //Functions can take an optional parameter, in this case the TWR to maintain is 1.5
   //                                          )).

   //launch_param:add("throttleProgramType", "function").
   //launch_param:add("throttleFunction", "cosine").
   //launch_param:add("throttleProfile", list( 
   //                                          1000, //Apo to Activate function, max prior
   //                                          launch_param["targetApo"] //Apo to Deactivate function 
   //                                          )).

     // Table based methods are the way to go, if you want exactly the right ascent for your specific rocket.
     // It can't be wrong if NASA uses it, right?
     // Reference Variables available: MET, APO, and etaAPO

     // The profile consists of a table of reference var, throttle setting pairs
     // For example, if the reference variable is altitude, you might have:
     // Altitude | Throttle setting
     //  2000    ,    1
     //  34000   ,    0.5
     //  70000   ,    0.1
     // Note: Setting applies UP TO the given point, NOT following that point.
     // Also Note: That the output is smoothed such that each point is effectively a fixed point on a curve.

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

   launch_param:add("throttleProgramType", "table").
   launch_param:add("throttleReferenceVar", "APO"). 
   launch_param:add("throttleProfile", list( 
                                             15000, 1,
                                             20000, 0.5,
                                             31000, 0.5,
                                             32000, 1,
                                             80000, 1
                                             )).

   //Upper stage
   // This tells the system which upper stage is installed.
   // This information is used primarily by the circularization burn.
   launch_param:add("upperstage", "poodle").

   //The system will display a countdown of this length before any launch.
   launch_param:add("countDownLength",      10).

   //Indicates use of a stage-and-a-half design, and altitude to force staging.
   //launch_param:add("stageandahalf", 34000).

   //launch_param:add("orbitType", "transfer").  //If transfer is selected, circularization is not performed and payload is expected to takeover.

   // These assume certain parts have been added to action groups
   // Activate AG1 at 60km (Jettison fairing)
   launch_param:add("AG1", 65000).
   // Activate AG2 at 65km (Activate solar panels and antennas)
   launch_param:add("AG2", 69000).
   // Force MECO Shutdown main engine and use upperstage/OMS to complete orbital insertion; after leaving atmosphere.
   //launch_param:add("AG10", ship:orbit:body:atm:height).
   
   //Initialize the launch system.
   launch_ctl["init"]().

   //Add a launch to LKO routine to the MISSIONPLAN
   launch_ctl["addLaunchToMissionPlan"]().
}

