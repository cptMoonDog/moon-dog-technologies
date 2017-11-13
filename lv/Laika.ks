@lazyglobal off.
//This is a standard Launch Vehicle parameter file.
//This holds the information necessary to customize the flight profile for your lifter.

{
   //Fudge factor  
   // Why this is needed: This script is capable of launching into inclined orbits, 
   // however the inclination is not achieved instantly upon launch, which means 
   // the Longitude of the Ascending node will be off slightly (in the direction of rotation).
   // To compensate this factor will activate the launch sequence this number of seconds prior to the 
   // calculated launch time. It is called Time of Flight, because the launch window lead time 
   // should be the same as the amount of time it takes to achieve the proper inclination, which 
   // will also be about the same as the amount of time needed to achieve orbital velocity.  
   // For the record, this will vary with the inclination.
   launch_param:add("timeOfFlight",         180).

   //Gravity turn parameters
   // Pitchover magnitude in degrees
   // Vertical speed at which to start pitchover
   // Vertical speed at which to handoff steering to prograde follower.
   launch_param:add("pOverDeg",             4). 
   launch_param:add("pOverV0",              30). 
   launch_param:add("pOverVf",              200).

   //Throttle program parameters
   // There are several throttle program types available.
   // This one maintains a set time to Apoapsis.
   //TODO Document available programs.
   launch_param:add("throttleProgramType", "etaApo").
   launch_param:add("throttleProfile", list( 
                           20000, //Apo to Activate function, max prior
                           80000, //Apo to Deactivate function 
                           45)).  //Setpoint

   //Upper stage
   // This tells the system which upper stage is installed.
   // This information is used primarily by the circularization burn.
   launch_param:add("upperstage", "doublethud").
}

