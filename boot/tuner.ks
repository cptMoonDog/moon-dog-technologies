@lazyglobal off.

until ship:altitude > 80000 {
      // Tuning Code
      if ship:altitude > 1000 
      if vang(ship:prograde:forevector, up:forevector) > 85 and ship:altitude < ship:orbit:body:atm:height {
         // Too much initial pitch
         local tunerFile is open("0:/tuner.ks").
         tunerFile:clear.

         tunerFile:writeln("@lazyglobal off.").
         tunerFile:writeln("launch_param:add("+char(34)+"tuner_dim"+char(34)+", "+char(34)+"pOverDeg"+char(34)+").").
         log "****************************" to "0:/tunerLog.txt".
         log "tuning: "+launch_param["tuner_dim"] to "0:/tunerLog.txt".

         tunerFile:writeln("launch_param:add("+char(34)+"tuner_last"+char(34)+", "+launch_param[launch_param["tuner_dim"]]+").").
         log "tuner_last: "+launch_param["tuner_last"] to "0:/tunerLog.txt".
         
         tunerFile:writeln("launch_param:add("+char(34)+"tuner_top"+char(34)+", "+launch_param[launch_param["tuner_dim"]]+").").
         log "tuner_top: "+launch_param[launch_param["tuner_dim"]] to "0:/tunerLog.txt".
         
         tunerFile:writeln("launch_param:add("+char(34)+"tuner_bottom"+char(34)+", "+launch_param["tuner_bottom"]+").").
         log "tuner_bottom: "+launch_param["tuner_bottom"] to "0:/tunerLog.txt".
         
         local newval is launch_param[launch_param["tuner_dim"]]-(launch_param[launch_param["tuner_dim"]]-launch_param["tuner_bottom"])/2.
         tunerFile:writeln("launch_param:add("+char(34)+launch_param["tuner_dim"]+char(34)+", "+newval +").").
         log "tuner_val: "+ newval to "0:/tunerLog.txt".

         if launch_param["tuner_top"] - launch_param["tuner_bottom"] < 0.25 
            kuniverse:pause().
         else if kuniverse:canreverttolaunch() kuniverse:reverttolaunch().

      } else if vang(ship:prograde:forevector, up:forevector) < 85 and ship:apoapsis > 79000 {
         // Not enough initial pitch
         local tunerFile is open("0:/tuner.ks").
         tunerFile:clear.

         tunerFile:writeln("@lazyglobal off.").
         tunerFile:writeln("launch_param:add("+char(34)+"tuner_dim"+char(34)+", "+char(34)+"pOverDeg"+char(34)+").").
         log "****************************" to "0:/tunerLog.txt".
         log "tuning: "+launch_param["tuner_dim"] to "0:/tunerLog.txt".

         tunerFile:writeln("launch_param:add("+char(34)+"tuner_last"+char(34)+", "+launch_param[launch_param["tuner_dim"]]+").").
         log "tuner_last: "+launch_param["tuner_last"] to "0:/tunerLog.txt".
         
         tunerFile:writeln("launch_param:add("+char(34)+"tuner_top"+char(34)+", "+launch_param["tuner_top"]+").").
         log "tuner_top: "+launch_param["tuner_top"] to "0:/tunerLog.txt".
         
         tunerFile:writeln("launch_param:add("+char(34)+"tuner_bottom"+char(34)+", "+launch_param[launch_param["tuner_dim"]]+").").
         log "tuner_bottom: "+launch_param[launch_param["tuner_dim"]] to "0:/tunerLog.txt".
         
         local newval is launch_param[launch_param["tuner_dim"]]+(launch_param["tuner_top"]-launch_param[launch_param["tuner_dim"]])/2.
         tunerFile:writeln("launch_param:add("+char(34)+""+launch_param["tuner_dim"]+""+char(34)+", "+newval +").").
         log "tuner_val: "+ newval to "0:/tunerLog.txt".

         if launch_param["tuner_top"] - launch_param["tuner_bottom"] < 0.25 
            kuniverse:pause().
         else if kuniverse:canreverttolaunch() kuniverse:reverttolaunch().
      }
}
