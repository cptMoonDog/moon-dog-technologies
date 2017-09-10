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
   local fairing is false. //Flag for ship having a fairing.
   local utilAG is false.  //Flag for ship having action group 1.
   local fairingJettisoned is false.
   local utilActive is false.

   //Init
   declare function init {
      declare parameter f.
      declare parameter u.

      set fairing to f.
      set utilAG to u.

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
                  break.
               }
            }
         }
         return OP_CONTINUE.
      } else return OP_FINISHED.
   }
   launch_ctl:add("staging", genStaging@).
}
