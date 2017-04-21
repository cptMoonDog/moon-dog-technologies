// Staging control staging_ctlrary for ascending rockets.
// James McConnel

{ // Start Library
   // Open a lexicon to collect the exportable functions.
   declare global staging_ctl is lexicon().

   declare function launch {
      print "launch initiated.".
      stage.
      wait 1.
      if ship:airspeed < 0.1 { //Some crafts (Kerbal X) throttles up before releasing clamps.
         stage.
      } 
      return NEXT_MODE.
   }
   staging_ctl:add("launch", launch@).

   declare function install_seqStaging { // TODO: Bad...fuel check will always come back true.
      print "installing Sequential Staging...".
      when (stage:liquidfuel < 0.05 OR stage:solidfuel < 0.05) AND stage:ready then {   //Sequential Staging
         list Engines in engList.
         if engList:length > 0 {
            stage.
            preserve.
         }
      }
   }
   
   local engList is 0.
   local lastTime is time:seconds.
   list Engines in engList.
   declare function genStaging {
      if engList:length > 0 {
         if time:seconds > lastTime + 0.5 {
            for eng in engList {
               if eng:ignition and eng:flameout {
                  stage.
                  list Engines in engList.
                  break.
               }
            }
         }
         return CONTINUE_MODE.
      } else return NEXT_MODE.
   }
   staging_ctl:add("staging", genStaging@).
}
