if not defined engineStat {
   local isp is lexicon().
   local thrust is lexicon().

   declare global defineEngine is {
      declare parameter name.
      declare parameter isp.
      declare parameter thrust.

      if not isp:haskey(name) {
         isp:add(name, isp).
         thrust:add(name, thrust).
      }
   }.

   declare global engineStat is {
      declare parameter name.
      declare parameter stat.
      if isp:haskey(name) {
         if stat="isp" return isp[name].
         if stat="thrust" return thrust[name].
         if stat="ff" return thrust[name]*1000/(isp[name]*9.80665).
      } else {
         //Fail 
         print "ENGINE: "+name+" DOES NOT EXIST IN THE DB.".
         print "COUGH...COUGH...GURGLE...GURGLE.".
         print "You watch helplessly as *NPC Name here* dies in your arms.".
         set OP_FAIL to true.
      }
   }.  
}
