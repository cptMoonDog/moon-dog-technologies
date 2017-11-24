if not defined engineStat {
   local isp is lexicon().
   local thrust is lexicon().

   isp:add("bollard", 325).
   thrust:add("bollard", 925).

   isp:add("terrier", 345).
   thrust:add("terrier", 60).

   isp:add("skipper", 320).
   thrust:add("skipper", 650).

   isp:add("doubleThud", 305).
   thrust:add("doubleThud", 240).

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
