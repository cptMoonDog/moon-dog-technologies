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
   local fairingJettisoned is false.
   local utilActive is false.

   //Init
   list Engines in engList.

///Public functions

   //Launch sequence
   declare function launch {
      print "launch initiated.".
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
         if time:seconds > lastTime + 1 {
            for eng in engList {
               if eng:ignition and eng:flameout {
                  stage.
                  list Engines in engList.
                  print engList.
                  break.
               }
            }
         }
         return OP_CONTINUE.
      } else return OP_FINISHED.
   }
   launch_ctl:add("staging", genStaging@).

///Private functions

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
}
