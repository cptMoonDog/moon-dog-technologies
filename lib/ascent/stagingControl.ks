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
      return OP_FINISHED.
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
   local fairingJettisoned is false.
   local utilActive is false.
   list Engines in engList.
   declare function genStaging {
      parameter fairing is false.
      parameter utilAG is false.
      if fairing and not fairingJettisoned and ship:altitude > 60000 {
         stage.
         set fairingJettisoned to true.
      }
      if utilAG and not utilActive and ship:altitude > 65000 {
         AG1 on.
         set utilActive to true.
      }
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
         return OP_CONTINUE.
      } else return OP_FINISHED.
   }
   staging_ctl:add("staging", genStaging@).
}
