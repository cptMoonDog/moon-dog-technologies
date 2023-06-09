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
            local avail is open("0:/programs").  
            for token in avail:lex():keys {
               if avail:lex[token]:isfile() set temp to temp + char(10) + "   " + token:split(".")[0].
            }
            set kernel_ctl["output"] to temp.
         }

         else if splitCmd[1] = "help" {                                                                                  //help: Gets the program's help message
            kernel_ctl["import-lib"]("programs/"+splitCmd[2]).
            if kernel_ctl["availablePrograms"]:haskey(splitCmd[2])
               kernel_ctl["availablePrograms"][splitCmd[2]](""). // Well behaved programs set kernel_ctl["status"] themselves.
            else set kernel_ctl["output"] to "Program does not exist". 
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
         return "finished".
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
      set launch_param["orbitType"] to cmd.
      set kernel_ctl["output"] to "   Type: "+cmd.
      if cmd = "coplanar" set kernel_ctl["prompt"] to "Target: ".
      else set kernel_ctl["prompt"] to "Inclination(*0*): ".
   }else if kernel_ctl["prompt"] = "Inclination(*0*): " {
      if cmd = "" set cmd to "0". //Default value
      set launch_param["inclination"] to cmd:tonumber(0).
      set kernel_ctl["output"] to "   Inclination: "+cmd.
      set kernel_ctl["prompt"] to "LAN(*none*): ".
   } else if kernel_ctl["prompt"] = "LAN(*none*): " {
      if cmd = "" set cmd to "none". //Default value
      if cmd:tonumber(-1) = -1 or launch_param["inclination"] = 0 {
         set launch_param["lan"] to "none".
         set launch_param["launchTime"] to "now".
      } else {
         set launch_param["lan"] to cmd:tonumber(0).
         set launch_param["launchTime"] to "window".
      }
      set kernel_ctl["output"] to "   LAN: "+cmd.
      set kernel_ctl["prompt"] to "Orbit height(*80000*): ".
   } else if kernel_ctl["prompt"] = "Target: " {
      set target to cmd.
      if hastarget { 
         set launch_param["lan"] to target:orbit:LAN.
         set launch_param["inclination"] to target:orbit:inclination.
         if abs(launch_param["inclination"]) < 0.5
            set launch_param["launchTime"] to "now".
         else set launch_param["launchTime"] to "window".
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
      else set launch_param["targetApo"] to cmd:tonumber(80000).    
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

local PLANE_MODE is false.
local pid is 0.
local turn_rate is 1.

SYS_CMDS:add("plane-mode", {
   declare parameter cmd.
   if PLANE_MODE set PLANE_MODE to false.
   else set PLANE_MODE to true.
   return "finished".
}).

declare function slowYourRoll {
   declare parameter compass.
   declare parameter p.
   declare parameter roll_local.
   local lastTime is 0.
   if vang(ship:facing:forevector, heading(compass, p, roll_local):forevector) > turn_rate and time:seconds > lastTime + 1 {
      local facingCompass is CHOOSE 360 - vang(vxcl(up:forevector, ship:facing:forevector), north:forevector)
         if vang(vxcl(up:forevector, ship:facing:forevector), heading(90, 0, 0):forevector) > 90 
         else vang(vxcl(up:forevector, ship:facing:forevector), north:forevector).
      local compassDir is CHOOSE -1 if facingCompass > compass else 1.
      set lastTime to time:seconds.
      return heading(facingCompass+turn_rate*compassDir, p, roll_local).
   } else {
      return heading(compass, p, roll_local) .
   }
}
SYS_CMDS:add("set-heading", {
   declare parameter cmd.
   local compass is 0.
   local p is 0.
   local roll_local is 0.
   if PLANE_MODE AND cmd:startswith("set-heading") {
      local splitCmd is cmd:split(" ").
      if splitCmd:length > 3 set roll_local to splitCmd[3]:tonumber(0).
      if splitCmd:length > 2 {
         set compass to splitCmd[1]:tonumber(0).
         set p to splitCmd[2]:tonumber(0).
      }
      lock steering to slowYourRoll(compass, p, roll_local).
   }
   return "finished".
}).

SYS_CMDS:add("unlock-steering", {
   declare parameter cmd.
   if PLANE_MODE AND cmd:startswith("unlock-steering") {
      unlock steering.
   }
   return "finished".
}).

SYS_CMDS:add("set-rate-descent", {
   declare parameter cmd.
   if PLANE_MODE AND cmd:startswith("set-rate-descent") {
      local splitCmd is cmd:split(" ").
      set pid to PIDLOOP().
      set pid:setpoint to -splitCmd[1]:tonumber(0).
      set pid:minoutput to 0.
      set pid:maxoutput to 1.
      lock throttle to pid:update(time:seconds, ship:verticalspeed).
   }
   return "finished".
}).

SYS_CMDS:add("set-rate-ascent", {
   declare parameter cmd.
   if PLANE_MODE AND cmd:startswith("set-rate-ascent") {
      local splitCmd is cmd:split(" ").
      set pid to PIDLOOP().
      set pid:setpoint to splitCmd[1]:tonumber(0).
      set pid:minoutput to 0.
      set pid:maxoutput to 1.
      lock throttle to pid:update(time:seconds, ship:verticalspeed).
   }
   return "finished".
}).

SYS_CMDS:add("set-rate-turning", {
   declare parameter cmd.
   if PLANE_MODE and cmd:startswith("set-rate-turning") {
      local splitCmd is cmd:split(" ").
      set turn_rate to splitCmd[1]:tonumber(1).
   }
   return "finished".
}).
