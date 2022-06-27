@lazyglobal off.

// Add a new command to the SYS_CMDS lexicon
SYS_CMDS:add("display", {
   declare parameter cmd.
   if cmd:startswith("display") { // Check to see what was actually passed.  This allows for subcommand behaviour
      local splitCmd is cmd:split(" ").
      if splitCmd:length > 1 {    // These are the things that we can display

         if      splitCmd[1] = "apo"      set kernel_ctl["output"] to "   "+ship:apoapsis.                               //apo
         else if splitCmd[1] = "pe"       set kernel_ctl["output"] to "   "+ship:periapsis.                              //pe
         else if splitCmd[1] = "altitude" set kernel_ctl["output"] to "   "+ship:altitude.                               //altitude

         else if splitCmd[1] = "mission-plan" {                                                                          //mission-plan
            local temp is "Mission Plan:"+char(10).
            local count is 0.
            for token in kernel_ctl["MissionPlanList"]() {
               set temp to temp + char(10) + "   "+ count + " " +token.
               set count to count + 1.
            }
            set kernel_ctl["output"] to temp.
         }

         else if splitCmd[1] = "commands" {                                                                              //commands
            local temp is "Available Commands:"+char(10).
            for token in SYS_CMDS:keys set temp to temp + char(10) + "   " + token.
            set kernel_ctl["output"] to temp.
         }

         else if splitCmd[1] = "programs" {                                                                              //programs
            local temp is "Available Programs:"+char(10).
            //TODO list available programs on command   
            local avail is open("0:/programs").  
            for token in avail:lex():keys {
               if avail:lex[token]:isfile() set temp to temp + char(10) + "   " + token:split(".")[0].
            }
            set kernel_ctl["output"] to temp.
         }

         else if splitCmd[1] = "help" {                                                                                  //help
            kernel_ctl["import-lib"]("programs/"+splitCmd[2]).
            kernel_ctl["availablePrograms"][splitCmd[2]]("").
         }

         else if splitCmd[1] = "eta-duna-window" {                                                                       //eta-duna-window
            if not (defined phys_lib) kernel_ctl["import-lib"]("lib/physics"). 
            set kernel_ctl["output"] to round(phys_lib["etaPhaseAngle"](ship:body, body("Duna"))):tostring+" seconds".
         } else set kernel_ctl["output"] to "   No data".
         return "finished".

      } else { // No displayable given, initiate subcommand interface.
         set kernel_ctl["prompt"] to "Display what?:".
         local temp is "Available Commands:"+char(10).
         for token in SYS_CMDS:keys set temp to temp + char(10) + "   " + token.
         set kernel_ctl["output"] to temp.
      }
   } else if kernel_ctl["prompt"] = "Display what?:" { // subcommands
      if cmd:trim:tolower = "apo" set kernel_ctl["output"] to ship:apoapsis.
      else if cmd:trim:tolower = "pe" set kernel_ctl["output"] to ship:periapsis.
      else if cmd:trim:tolower = "mission-elements" set kernel_ctl["output"] to MISSION_PLAN:length.
      else if cmd:trim:tolower = "altitude" set kernel_ctl["output"] to ship:altitude.
      else set kernel_ctl["output"] to "   No data".
      return "finished".
   }
}).

SYS_CMDS:add("setup-launch", {
   declare parameter cmd.
   if cmd = "setup-launch" { // Primary command entry
      if ship:status = "PRELAUNCH" or ship:status = "LANDED" {
         kernel_ctl["import-lib"]("lib/launch/launch_ctl").
         set kernel_ctl["prompt"] to "Type(*lko*/coplanar/transfer): ".
      } else {
         set kernel_ctl["output"] to "   Not on launch pad".
         return "finished".
      }
   // Secondary input items
   }else if kernel_ctl["prompt"] = "Type(*lko*/coplanar/transfer): " {
      if cmd = "" set cmd to "lko". //Default value
      launch_param:add("orbitType", cmd).
      set kernel_ctl["output"] to "   Type: "+cmd.
      if cmd = "coplanar" set kernel_ctl["prompt"] to "Target: ".
      else set kernel_ctl["prompt"] to "Inclination(*0*): ".
   }else if kernel_ctl["prompt"] = "Inclination(*0*): " {
      if cmd = "" set cmd to "0". //Default value
      launch_param:add("inclination", cmd:tonumber(0)).
      set kernel_ctl["output"] to "   Inclination: "+cmd.
      set kernel_ctl["prompt"] to "LAN(*none*): ".
   } else if kernel_ctl["prompt"] = "LAN(*none*): " {
      if cmd = "" set cmd to "none". //Default value
      if cmd:tonumber(-1) = -1 or launch_param["inclination"] = 0 {
         launch_param:add("lan", "none").
         launch_param:add("launchTime", "now").
      } else {
         launch_param:add("lan", cmd:tonumber(0)).
         launch_param:add("launchTime", "window").
      }
      set kernel_ctl["output"] to "   LAN: "+cmd.
      set kernel_ctl["prompt"] to "Orbit height(*80000*): ".
   } else if kernel_ctl["prompt"] = "Target: " {
      set target to cmd.
      if hastarget { 
         launch_param:add("lan", target:orbit:LAN).
         launch_param:add("inclination", target:orbit:inclination).
         if abs(launch_param["inclination"]) < 0.5
            launch_param:add("launchTime", "now").
         else launch_param:add("launchTime", "window").
      } else {
         set kernel_ctl["output"] to "   Target does not exist.".
         return "finished".
      }
      set kernel_ctl["output"] to "   Target: "+cmd.
      set kernel_ctl["prompt"] to "Orbit height(*80000*): ".
   } else if kernel_ctl["prompt"] = "Orbit height(*80000*): " {
      if cmd = "" set cmd to "80000". //Default value
      if cmd:trim:endswith("k") or cmd:trim:endswith("km") launch_param:add("targetApo", cmd:trim:remove(cmd:trim:length-1, 1):tonumber(80)*1000).
      else if cmd:tonumber(-1) = -1 launch_param:add("targetApo", 80000).    
      else launch_param:add("targetApo", cmd:tonumber(80000)).    
      set kernel_ctl["output"] to "   Orbit height: "+cmd.
      set kernel_ctl["prompt"] to "Launch Vehicle: ".
   } else if kernel_ctl["prompt"] = "Launch Vehicle: " {
      if cmd:trim and exists("0:/lv/"+cmd:trim+".ks") {
         kernel_ctl["import-lib"]("lv/"+cmd:trim). 
         set kernel_ctl["output"] to "   Launch Vehicle: "+cmd.
      } else set kernel_ctl["output"] to "   Launch Vehicle: "+cmd+" not found".
      set kernel_ctl["prompt"] to ":".
      return "finished".
   }
}).

SYS_CMDS:add("change-callsign", {
   declare parameter cmd.
   if cmd:startswith("change-callsign") {
      local splitCmd is cmd:split(" ").
      set ship:name to cmd:remove(0, splitCmd[0]:length):trim.
      return "finished".
   }
}).

// Program specific commands
SYS_CMDS:add("add-program", {
   declare parameter cmd.
   if cmd:startswith("add-program") {
      local splitCmd is cmd:split(" ").
      if splitCmd:length > 1 and exists("0:/programs/"+splitCmd[1]+".ks") {
         kernel_ctl["import-lib"]("programs/"+splitCmd[1]).
      } else {
         set kernel_ctl["output"] to "Program does not exist".
         return "finished".
      }
      if kernel_ctl["availablePrograms"]:haskey(splitCmd[1]) {
         local retVal is kernel_ctl["availablePrograms"][splitCmd[1]](cmd:remove(0, "add-program":length+splitCmd[1]:length+1):trim).
         if retVal = OP_FAIL set kernel_ctl["output"] to "Unable to initialize, check arguments.".
         return "finished".                                                                                                                                      
      } else {
         set kernel_ctl["output"] to "Program does not exist in the lexicon".
         return "finished".
      }
   }                                                                               
}).

SYS_CMDS:add("remove-program", {
   declare parameter cmd.
   if cmd:startswith("remove-program") {
      local splitCmd is cmd:split(" ").
      if splitCmd:length > 1 {
         if splitCmd[1]:tonumber(-1) > -1 { // index number
            kernel_ctl["MissionPlanRemove"](splitCmd[1]:tonumber(0)).
         } else if MISSION_PLAN_ID:find(splitCmd[1]) > -1 { // ID 
            kernel_ctl["MissionPlanRemove"](kernel_ctl["MissionPlanList"]:find(splitCmd[1])).
         }
      }
      return "finished".
   }                                                                               
}).


SYS_CMDS:add("run-extra", {
   declare parameter cmd.
   if cmd:startswith("run-extra") {
      local splitCmd is cmd:split(" ").
      runpath("0:/extra/"+splitCmd[1]+".ks"). // Do not route through import-lib.  These should be re-runnable.
      return "finished".
   }
}).

SYS_CMDS:add("draw-vector", {
   declare parameter cmd.
   if cmd:startswith("draw-vector") {
      local splitCmd is cmd:split(" ").
      if splitCmd:length > 1 { 
         local origin is v(0,0,0).
         //if splitCmd[1] = "body" set origin to {return ship:body:position.}.
         local directionVector is v(0,0,0).
         //{return north:forevector.}.
         //if splitCmd[2] = "UP" {return up:forevector}.
         
         local test is vecdraw(
                                 origin, 
                                 directionVector,
                                 RGB(1, 0, 0),
                                 "North",
                                 1,
                                 true,
                                 0.2,
                                 true,
                                 true).
      } else {
         set kernel_ctl["output"] to
            "Draws a vector on the screen."
            +char(10)+"Usage: draw-vector [ORIGIN] [DIRECTION] [COLOR] [LABEL]"
            +char(10)+"   where [ORIGIN] is ship or body"
            +char(10)+"   [DIRECTION] is AN, DN, LAN, UP, DOWN, NORTH, SOUTH, SPV, MAX or MIN"
            +char(10)+"   [COLOR] is red green or blue"
            +char(10)+"   [LABEL] is some text".

         return "finished".
      }
   }
}).

SYS_CMDS:add("clear-drawings", {
   declare parameter cmd.
   if cmd:startswith("clear-drawings") {
      clearvecdraws().
      return "finished".
   }
}).
