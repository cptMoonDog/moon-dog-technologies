@lazyglobal off.
{
              //Fudge factor
              launch_param:add("timeOfFlight",         100).

              //Gravity turn parameters
              launch_param:add("pOverDeg",             4.5). 
              launch_param:add("pOverV0",              30). 
              launch_param:add("pOverVf",              150).
              //Throttle program parameters
              //Throttle program for Upgoer 3 on laptop
//              "throttleProgramType", "tableAPO", 
//              "throttleProfile", list(
//                                      15000, 1,
//                                      30000, 0.5,
//                                      50000, 0.3,
//                                      55000, 0.75,
//                                      80000, 0.5

              //Throttle program for Upgoer 3 on desktop
//              launch_param:add("throttleProgramType", "tableAPO").
//              launch_param:add("throttleProfile", list(
//                                      5000, 1,
//                                      35000, 0.25,
//                                      50000, 1,
//                                      70000, 0.2,
//                                      75000, 0.5,
//                                      80000, 1)).
//
//              "throttleProgramType", "tableMET", 
//              "throttleProfile", list(
//                                      60, 1,
//                                      120, 0.5,
//                                      240, 0.25,
//                                      320, 0.1
//
              launch_param:add("throttleProgramType", "etaApo").
              launch_param:add("throttleProfile", list( 
                                      20000, //Apo to Activate function, max prior
                                      80000, //Apo to Deactivate function 
                                      45)).     //Setpoint

                                    

}

