// Staging control staging_ctlrary for ascending rockets.
//Mon Jun 19 21:01:08 PDT 2017
// James McConnel

@LAZYGLOBAL OFF.
// Start Library
{ 
   // Open a lexicon to collect the exportable functions.
   if not (defined launch_ctl) {
      declare global launch_ctl is lexicon().
   }

   // Local variables
   local engList is 0.
   local lastTime is time:seconds.
   local twr is 0.

   //Init
   declare function init {
      list Engines in engList.
   }
   launch_ctl:add("init_staging", init@).


///Public functions

   //Launch sequence
   declare function launch {
      stage.
      wait 1.
      if ship:airspeed < 0.1 { //Some crafts (Kerbal X) throttles up before releasing clamps.
         stage.
      } 
      return OP_FINISHED.
   }
   launch_ctl:add("launch", launch@).

   //current staging trigger
   declare function genStaging {
      if launch_param:haskey("AG1") and ship:altitude > launch_param["AG1"] {
        AG1 on.
        launch_param:remove("AG1").
      }
      if launch_param:haskey("AG2") and ship:altitude > launch_param["AG2"] {
        AG2 on.
        launch_param:remove("AG2").
      }
      if launch_param:haskey("AG3") and ship:altitude > launch_param["AG3"] {
        AG3 on.
        launch_param:remove("AG3").
      }
      if launch_param:haskey("AG4") and ship:altitude > launch_param["AG4"] {
        AG4 on.
        launch_param:remove("AG4").
      }
      if launch_param:haskey("AG5") and ship:altitude > launch_param["AG5"] {
        AG5 on.
        launch_param:remove("AG5").
      }
      if launch_param:haskey("AG6") and ship:altitude > launch_param["AG6"] {
        AG6 on.
        launch_param:remove("AG6").
      }
      if launch_param:haskey("AG7") and ship:altitude > launch_param["AG7"] {
        AG7 on.
        launch_param:remove("AG7").
      }
      if launch_param:haskey("AG8") and ship:altitude > launch_param["AG8"] {
        AG8 on.
        launch_param:remove("AG8").
      }
      if launch_param:haskey("AG9") and ship:altitude > launch_param["AG9"] {
        AG9 on.
        launch_param:remove("AG9").
      }
      if launch_param:haskey("AG10") and ship:altitude > launch_param["AG10"] {
        AG10 on.
        launch_param:remove("AG10").
      }
      
      if engList:length > 0 {
         if time:seconds > lastTime + 1 {
            local thrst is 0.
            for eng in engList 
               set thrst to thrst + eng:thrust.
            set twr to thrst/ship:mass.
                                                       //TWR reference value                  Altitude Ref
            if launch_param:haskey("stageAndAHalf") and (twr > launch_param["stageAndAHalf"] or ship:altitude > launch_param["stageAndAhalf"]) {
               stage.
               launch_param:remove("stageAndAHalf").
            } else for eng in engList {
               if eng:ignition and eng:flameout {
                  if engList:length > 1 {
                     stage.
                     list Engines in engList.
                     break.
                  }
               }
            }
         }
         return OP_CONTINUE.
      } else return OP_FINISHED.
   }
   launch_ctl:add("staging", genStaging@).

   declare function actionGroup
}
