@lazyglobal off.

SYS_CMDS_HELP:add("missions", char(10)+
   "Missions are your system firmware."+char(10)+
   "   There are two distinct systems in MDTech, for the other see 'help programs'."+char(10)+
   "   Missions are, simply put, bootfile hacking."+char(10)+
   "   The 'lv.ks' and 'payload.ks' boot files can swap in a"+char(10)+
   "   '0:/missions' file of your choice post-launch as an on-orbit bootfile."+char(10)+
   +char(10)+
   "   Following this method, it is possible to reconfigure the spacecraft"+char(10)+
   "   repeatedly as mission requirements change.  "+char(10)+
   "   See the examples in '0:/missions' for mission design help."+char(10)+
   char(10)
).

SYS_CMDS_HELP:add("programs", char(10)+
   "Programs are pre-defined sequential routines for common tasks."+char(10)+
   "   There are two distinct systems in MDTech, for the other see 'help missions'."+char(10)+
   "   The heart and soul of MDTech, is a kernel executing a 'MISSION_PLAN'."+char(10)+
   "   The 'MISSION_PLAN' is simply a list populated with routines to be run in order."+char(10)+
   "   When you run the command 'Q' the routines defined for that program"+char(10)+
   "   are added to the 'MISSION_PLAN'.  "+char(10)+
   "   The command 'start' will begin execution of the 'MISSION_PLAN'"+char(10)+
   +char(10)+
   "   For more information about defining your own programs"+char(10)+
   "   See the examples in '0:/programs'"+char(10)+
   char(10)
).

SYS_CMDS_HELP:add("core-tag", char(10)+
   "The core tag is the name tag of the kOS processor this program is running on."+char(10)+
   "   It is the first place the boot files check for parameters."+char(10)+
   "   For the 'lv.ks' bootfile, you can specify:"+char(10)+
   "      [LV Name], [Target Name] | [[Inclination], [LAN], [Orbit Height]]"+char(10)+
   "         Or"+char(10)+
   "      <name>.launch to source from a parameters file in '0:/launch.conf'"+char(10)+char(10)+
   "   Parameters are optional, but order is important."+char(10)+char(10)+
   "   For the 'payload.ks' bootfile, you can specify:"+char(10)+
   "      [Spacecraft Name]:[Mission Name], [Param 1], ... [Param N]"+char(10)+char(10)
).

// Add a new command to the SYS_CMDS lexicon
SYS_CMDS_HELP:add("help", char(10)+
   "Displays help information."+char(10)+
   "   Usage: help [topic]"+char(10)+
   "   help --topics : For a list of general helps."+char(10)+
   "   help --list-commands : For a list of system commands."+char(10)+
   "   help --list-programs : For a list of runnable programs."+char(10)+
   "   help --list-vars : For a list of displayable environment variables."+char(10)+
   "   help --list-lv : For a list of configured launch vehicles."+char(10)+
   "   help --list-missions : For a list of configured launch vehicles."+char(10)+
   "   Try:"+char(10)+
   "      help [Program Name]"+char(10)+
   "          or "+char(10)+
   "      help [Command Name]"+char(10)+
   "   for more specific help."
).
SYS_CMDS:add("help", {
   declare parameter cmd.
   if cmd:startswith("help") { // Check to see what was actually passed.  This allows for subcommand behaviour
      local splitCmd is cmd:split(" ").
      if splitCmd:length > 1 {    // These are the things that we can display
         local topic is splitCmd[1].
         kernel_ctl["import-lib"]("programs/"+topic).
         if kernel_ctl["availablePrograms"]:haskey(topic)
            kernel_ctl["availablePrograms"][topic](""). // Well behaved programs set kernel_ctl["output"] themselves.
         else if SYS_CMDS_HELP:haskey(topic) set kernel_ctl["output"] to SYS_CMDS_HELP[topic].
         else if topic = "--list-commands" {                                                                              //commands
            local temp is char(10)+"Commands:"+char(10).
            for token in SYS_CMDS:keys set temp to temp + char(10) + "   " + token.
            set kernel_ctl["output"] to temp.
         } else if topic = "--list-programs" {                                                                              //programs
            local temp is char(10)+"Programs:"+char(10).
            local avail is open("0:/programs").  
            for token in avail:lex():keys {
               if avail:lex[token]:isfile() set temp to temp + char(10) + "   " + token:split(".")[0].
            }
            set kernel_ctl["output"] to temp.
         } else if topic = "--list-lv" {                                                                              //Launch Vehicles
            local temp is char(10)+"Configured Launch Vehicles:"+char(10).
            local avail is open("0:/lv").  
            for token in avail:lex():keys {
               if avail:lex[token]:isfile() and avail:lex[token]:extension = "ks" set temp to temp + char(10) + "   " + token:split(".")[0].
            }
            set kernel_ctl["output"] to temp.
         } else if topic = "--list-missions" {                                                                              //Missions
            local temp is char(10)+"Available Firmware:"+char(10).
            local avail is open("0:/missions").  
            for token in avail:lex():keys {
               if avail:lex[token]:isfile() and avail:lex[token]:extension = "ks" set temp to temp + char(10) + "   " + token:split(".")[0].
            }
            set kernel_ctl["output"] to temp.
         } else if topic = "--list-vars" {                                                                                  //help: Gets the program's help message
            set kernel_ctl["output"] to char(10)+"Displayable variables: "+char(10)+
               "   apo"+char(10)+
               "   pe"+char(10)+
               "   altitude"+char(10)+
               "   time"+char(10)+
               "   ipu"+char(10)+
               "   mission-plan"+char(10)+
               "   commands"+char(10)+
               "   programs"+char(10)+
               "   eta-duna-window".
         } else if topic = "--topics" {                                                                                  //help: Gets the program's help message
            local temp is char(10)+"Help topics:"+char(10).
            for token in SYS_CMDS_HELP:keys set temp to temp + char(10) + "   " + token.
            set kernel_ctl["output"] to temp.
         } else set kernel_ctl["output"] to SYS_CMDS_HELP["help"]. 

         return "finished".
      } else {
         set kernel_ctl["output"] to SYS_CMDS_HELP["help"]. 
         return "finished".
      }
   }
}).
SYS_CMDS_HELP:add("display", char(10)+
   "Displays the requested system value."+char(10)+
   "   Usage: display [PARAMETER]"+char(10)+
   "   For a list of values use: help --list-vars"
).
SYS_CMDS:add("display", {
   declare parameter cmd.
   if cmd:startswith("display") OR kernel_ctl["prompt"] = "Display what?:" { // Check to see what was actually passed.  This allows for subcommand behaviour
      local splitCmd is cmd:split(" ").
      if splitCmd:length > 1 OR kernel_ctl["prompt"] = "Display what?:" {    // These are the things that we can display
         local item is choose splitCmd[1] if cmd:startswith("display") else cmd.

         if      item = "ap"      set kernel_ctl["output"] to "   "+ship:apoapsis.                               //apo
         else if item = "pe"       set kernel_ctl["output"] to "   "+ship:periapsis.                              //pe
         else if item = "eccentricity"  set kernel_ctl["output"] to "   "+ship:orbit:eccentricity.                              //eccentricity
         else if item = "altitude" set kernel_ctl["output"] to "   "+ship:altitude.                               //altitude
         else if item = "latitude" set kernel_ctl["output"] to "   "+ship:geoposition:lat.                        //latitude
         else if item = "longitude" set kernel_ctl["output"] to "   "+ship:geoposition:lng.                       //longitude
         else if item = "time"     set kernel_ctl["output"] to "   "+time:clock.                                  //time
         else if item = "ipu"      set kernel_ctl["output"] to "   "+config:ipu.                                  //Instructions per update
         else if item = "eta" {
            if splitCmd:length > 2 {
               if splitCmd[2] = "ap" set kernel_ctl["output"] to "   "+eta:apoapsis.
               else if splitCmd[2] = "pe" set kernel_ctl["output"] to "   "+eta:periapsis.
            }
         } else if item = "dvTo"  {
            if not (defined phys_lib) kernel_ctl["import-lib"]("lib/physics"). 
            if splitCmd:length > 2 {
               set kernel_ctl["output"] to "   "+(phys_lib["VatAlt"](ship:orbit:body, ship:altitude, phys_lib["sma"](ship:orbit:body, ship:altitude, splitCmd[2]:toNumber(-1)))-ship:velocity:orbit:mag).
            }
         } else if item = "mission"  set kernel_ctl["output"] to "   "+core:bootfilename.                           //current mission (bootfile)
         else if item = "mission-plan" {                                                                          //mission-plan
            local temp is "Mission Plan:"+char(10).
            local count is 0.
            for token in kernel_ctl["MissionPlanList"]() {
               set temp to temp + char(10) + "   "+ count + " " +token.
               if count = kernel_ctl["currentRunmode"] - 1 set temp to temp +" <---".
               set count to count + 1.
            }
            set kernel_ctl["output"] to temp.
         } else if item = "eta-duna-window" or item = "etaPole" {                                                                       //eta-duna-window
            if not (defined phys_lib) kernel_ctl["import-lib"]("lib/physics"). 
            if item = "eta-duna-window" set kernel_ctl["output"] to round(phys_lib["etaPhaseAngle"](ship:body, body("Duna"))):tostring+" seconds".
            else set kernel_ctl["output"] to round(phys_lib["etaAnglePastANDN"]("DN", 90)):tostring+" seconds".
         } else if item = "launchParam" {
            if (defined launch_param) {
               if splitCmd:length > 2 set kernel_ctl["output"] to "   "+launch_param[splitCmd[2]].
               else set kernel_ctl["output"] to "keys: "+launch_param:keys.
            } else set kernel_ctl["output"] to "Not defined".
         } else set kernel_ctl["output"] to "   No data".
         return "finished".

      } else { // No displayable given, initiate subcommand interface.
         set kernel_ctl["prompt"] to "Display what?:".
         local temp is "Available Commands:"+char(10).
         for token in SYS_CMDS:keys set temp to temp + char(10) + "   " + token.
         set kernel_ctl["output"] to temp.
      }
   }
}).

SYS_CMDS_HELP:add("setup-launch",
   char(10)+
   "Launch Control Wizard"+char(10)+
   "  Allows you to input your launch parameters"+char(10)+
   "  for a custom launch, or provides sensible defaults."+char(10)+
   "  If you are on the launch pad, and you have provided a "+char(10)+
   "  Launch Vehicle Definition file in '0:/lv', this will "+char(10)+
   "  add the necessary launch routines to the Mission Plan."+char(10)+
   +char(10)+
   "  Once the launch is added, you can optionally add additional"+char(10)+
   "   programs, before you call 'engage'."
).
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
      else set kernel_ctl["prompt"] to "Inclination(*0*/polar/retro/molniya): ".
   }else if kernel_ctl["prompt"] = "Inclination(*0*/polar/retro/molniya): " {
      if cmd = "" set cmd to "0". //Default value
      else if cmd = "polar" set cmd to "90".
      else if cmd = "equitorial" set cmd to "0".
      else if cmd = "retro" set cmd to "180".
      else if cmd = "molniya" set cmd to "63.4".
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
      } else set kernel_ctl["output"] to "Error. Failed to initialize launch: Launch Vehicle: "+cmd+" not found".
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
SYS_CMDS_HELP:add("add-program",
   char(10)+
   "Depreciated.  See Q or add"
).
SYS_CMDS_HELP:add("add",
   char(10)+
   "Queues the given program in the Mission Plan."+char(10)+
   "   Usage: add [Program Name] [Program Parameters...]"
).
SYS_CMDS_HELP:add("Q",
   char(10)+
   "Queues the given program in the Mission Plan."+char(10)+
   "   Usage: Q [Program Name] [Program Parameters...]"
).
SYS_CMDS:add("add", {
   declare parameter cmd.
   if cmd:startswith("add") {
      local splitCmd is cmd:split(" ").
      if splitCmd:length > 1 and exists("0:/programs/"+splitCmd[1]+".ks") {
         kernel_ctl["import-lib"]("programs/"+splitCmd[1]).
      } else {
         set kernel_ctl["output"] to "Program does not exist".
         return "finished".
      }
      if kernel_ctl["availablePrograms"]:haskey(splitCmd[1]) {
         local retVal is kernel_ctl["availablePrograms"][splitCmd[1]](cmd:remove(0, "add":length+splitCmd[1]:length+1):trim).
         if retVal = OP_FAIL set kernel_ctl["output"] to "Unable to initialize, check arguments.".
         return "finished".                                                                                                                                      
      } else {
         set kernel_ctl["output"] to "Program does not exist in the lexicon".
         return "finished".
      }
   }                                                                               
}).
SYS_CMDS:add("Q", {
   declare parameter cmd.
   if cmd:startswith("Q") {
      local splitCmd is cmd:split(" ").
      if splitCmd:length > 1 and exists("0:/programs/"+splitCmd[1]+".ks") {
         kernel_ctl["import-lib"]("programs/"+splitCmd[1]).
      } else {
         set kernel_ctl["output"] to "Program does not exist".
         return "finished".
      }
      if kernel_ctl["availablePrograms"]:haskey(splitCmd[1]) {
         local retVal is kernel_ctl["availablePrograms"][splitCmd[1]](cmd:remove(0, "Q":length+splitCmd[1]:length+1):trim).
         if retVal = OP_FAIL set kernel_ctl["output"] to "Unable to initialize, check arguments.".
         return "finished".                                                                                                                                      
      } else {
         set kernel_ctl["output"] to "Program does not exist in the lexicon".
         return "finished".
      }
   }                                                                               
}).

SYS_CMDS_HELP:add("remove",
   char(10)+
   "Removes the given program from the Mission Plan."+char(10)+
   "   Usage: remove [Program ID] | [Mission Plan index number]"
).
SYS_CMDS:add("remove", {
   declare parameter cmd.
   if cmd:startswith("remove") {
      local splitCmd is cmd:split(" ").
      if splitCmd:length > 1 {
         if splitCmd[1]:tonumber(-1) > -1 { // index number
            kernel_ctl["MissionPlanRemove"](splitCmd[1]:tonumber(0)).
         } else if kernel_ctl["MissionPlanList"]():find(splitCmd[1]) > -1 { // ID 
            kernel_ctl["MissionPlanRemove"](kernel_ctl["MissionPlanList"]():find(splitCmd[1])).
         }
      }
      return "finished".
   }                                                                               
}).

//SYS_CMDS_HELP:add("I


SYS_CMDS_HELP:add("extra",
   char(10)+
   "Runs a script found in '0:/extra'."+char(10)+
   "   Usage: extra [basename]"
).
SYS_CMDS:add("extra", {
   declare parameter cmd.
   if cmd:startswith("extra") {
      local splitCmd is cmd:split(" ").
      local filePath is "0:/extra/"+splitCmd[1]+".ks".
      if exists(filePath) runpath("0:/extra/"+splitCmd[1]+".ks"). // Do not route through import-lib.  These should be re-runnable.
      else set kernel_ctl["output"] to "Script: "+splitCmd[1]+" does not exist".
      lock throttle to 0.
      lock steering to ship:facing:forevector.
      return "finished".
   }
}).

SYS_CMDS_HELP:add("sys", 
   char(10)+
   "Runs one of the following system commands."+char(10)+
   "   Usage: sys [Command String]"+char(10)+char(10)+
   "Currently implemented:"+char(10)+
   "   reboot"+char(10)+
   "   shutdown"
).
SYS_CMDS:add("sys", {
   declare parameter cmd.
   if cmd:startswith("sys") {
      local splitCmd is cmd:split(" ").
      if splitCmd[1]:trim = "reboot" reboot.
      if splitCmd[1]:trim = "shutdown" shutdown.
      return "finished".
   }
}).

SYS_CMDS_HELP:add("set", 
  char(10)+
  "Sets various configurables"+char(10)+
  "   Usage: set [variable] [value]"+char(10)+
  "   Variables: "+char(10)+
  "      target"+char(10)+
  "      mission"
).
SYS_CMDS:add("set", {
   declare parameter cmd.
   if cmd:startswith("set") {
      local splitCmd is cmd:split(" ").
      if splitCmd:length <> 3 {
         set kernel_ctl["output"] to "Invalid command format".
         return "finished".
      }
      if splitCmd[1]:toLower() = "target" {
         set target to splitCmd[2].
         set kernel_ctl["output"] to "target set to: "+splitCmd[2].
      } else if splitCmd[1]:toLower() = "mission" {
         if exists("0:/missions/"+splitCmd[2]+".ks") {
            deletepath("1:/boot").
            createdir("1:/boot").
            compile "0:/missions/"+splitCmd[2]+".ks" to "1:/boot/"+splitCmd[2]+".ksm".
            set core:bootfilename to "/boot/"+splitCmd[2]+".ksm".
            set kernel_ctl["output"] to "mission (bootfile) set to: "+splitCmd[2].
         } else set kernel_ctl["output"] to "mission: "+splitCmd[2]+" does not exist.".
      }
   }
   return "finished".
}).

//SYS_CMDS:add("draw-vector", {
//   declare parameter cmd.
//   if cmd:startswith("draw-vector") {
//      local splitCmd is cmd:split(" ").
//      if splitCmd:length > 1 { 
//         local origin is v(0,0,0).
//         //if splitCmd[1] = "body" set origin to {return ship:body:position.}.
//         local directionVector is v(0,0,0).
//         //{return north:forevector.}.
//         //if splitCmd[2] = "UP" {return up:forevector}.
//         
//         local test is vecdraw(
//                                 origin, 
//                                 directionVector,
//                                 RGB(1, 0, 0),
//                                 "North",
//                                 1,
//                                 true,
//                                 0.2,
//                                 true,
//                                 true).
//      } else {
//         set kernel_ctl["output"] to
//            "Draws a vector on the screen."
//            +char(10)+"Usage: draw-vector [ORIGIN] [DIRECTION] [COLOR] [LABEL]"
//            +char(10)+"   where [ORIGIN] is ship or body"
//            +char(10)+"   [DIRECTION] is AN, DN, LAN, UP, DOWN, NORTH, SOUTH, SPV, MAX or MIN"
//            +char(10)+"   [COLOR] is red green or blue"
//            +char(10)+"   [LABEL] is some text".
//
//         return "finished".
//      }
//   }
//}).
//
//SYS_CMDS:add("clear-drawings", {
//   declare parameter cmd.
//   if cmd:startswith("clear-drawings") {
//      clearvecdraws().
//      return "finished".
//   }
//}).

local PLANE_MODE is false.
local pid is 0.
local turn_rate is 1.

SYS_CMDS_HELP:add("plane-mode",
   char(10)+
   "EXPERIMENTAL: Adds some aircraft control features to the shell. "
).
SYS_CMDS:add("plane-mode", {
   declare parameter cmd.
   if PLANE_MODE set PLANE_MODE to false.
   else {
      set PLANE_MODE to true.
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
   }
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
