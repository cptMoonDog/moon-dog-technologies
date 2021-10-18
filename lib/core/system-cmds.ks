@lazyglobal off.

SYS_CMDS:add("display", {
   declare parameter cmd.
   if cmd:startswith("display") {
      local splitCmd is cmd:split(" ").
      if splitCmd:length > 1 {
         if splitCmd[1] = "apo" set kernel_ctl["output"] to "   "+ship:apoapsis.
         else if splitCmd[1] = "pe" set kernel_ctl["output"] to "   "+ship:periapsis.
         else if splitCmd[1] = "mission-elements" set kernel_ctl["output"] to "   "+MISSION_PLAN:length.
         else if splitCmd[1] = "altitude" set kernel_ctl["output"] to "   "+ship:altitude.
         else set kernel_ctl["output"] to "   No data".
         return "finished".
      } else set kernel_ctl["prompt"] to "Display what?:".
   } else if kernel_ctl["prompt"] = "Display what?:" {
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
         runoncepath("0:/lib/launch/launch_ctl.ks").
         set kernel_ctl["prompt"] to "Type(*lko*/coplanar): ".
      } else {
         set kernel_ctl["output"] to "   Not on launch pad".
         return "finished".
      }
   // Secondary input items
   }else if kernel_ctl["prompt"] = "Type(*lko*/coplanar): " {
      if cmd = "" set cmd to "lko". //Default value
      launch_param:add("orbitType", cmd).
      set kernel_ctl["output"] to "   Type: "+cmd.
      if cmd = "lko" set kernel_ctl["prompt"] to "Inclination(*0*): ".
      else if cmd = "coplanar" set kernel_ctl["prompt"] to "Target: ".
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
      // TODO support dummy targets like: Polar
      set target to cmd.
      launch_param:add("inclination", target:orbit:inclination).
      if cmd:tonumber(-1) = -1 or launch_param["inclination"] = 0 {
         launch_param:add("lan", "none").
         launch_param:add("launchTime", "now").
      } else {
         launch_param:add("lan", target:orbit:LAN).
         launch_param:add("launchTime", "window").
      }
      set kernel_ctl["output"] to "   Target: "+cmd.
      set kernel_ctl["prompt"] to "Orbit height(*80000*): ".
   } else if kernel_ctl["prompt"] = "Orbit height(*80000*): " {
      if cmd = "" set cmd to "80000". //Default value
      if cmd:tonumber(-1) = -1 launch_param:add("targetApo", 80000).    
      else launch_param:add("targetApo", cmd:tonumber(80000)).    
      set kernel_ctl["output"] to "   Orbit height: "+cmd.
      set kernel_ctl["prompt"] to "Launch Vehicle: ".
   } else if kernel_ctl["prompt"] = "Launch Vehicle: " {
      if exists("0:/lv/"+cmd:trim+".ks") {
         runoncepath("0:/lv/"+cmd:trim+".ks"). 
         set kernel_ctl["output"] to "   Launch Vehicle: "+cmd.
      } else set kernel_ctl["output"] to "   Launch Vehicle: "+cmd+" not found".
      set kernel_ctl["prompt"] to ":".
      return "finished".
   }
}).

// Program specific commands
SYS_CMDS:add("add-program", {
   declare parameter cmd.
   if cmd:startswith("add-program") {
      local splitCmd is cmd:split(" ").
      if splitCmd:length > 1 and exists("0:/programs/"+splitCmd[1]+".ks") {
         runoncepath("0:/programs/"+splitCmd[1]+".ks").
      } else {
         set kernel_ctl["output"] to "Program does not exist".
         return "finished".
      }
      if available_programs:haskey(splitCmd[1]) {
         available_programs[splitCmd[1]](cmd:remove(0, "add-program":length+splitCmd[1]:length+1):trim).
         return "finished".                                                                                                                                      
      } else {
         set kernel_ctl["output"] to "Program does not exist in the lexicon".
         return "finished".
      }
   }                                                                               
}).
         
      
SYS_CMDS:add("stow-program", {
   declare parameter cmd.
   if cmd:startswith("stow-program") {
      local splitCmd is cmd:split(" ").
      //if exists("0:/stowed.json") local stowed is readjson("0:/stowed.json").
      //else local stowed is lexicon().
      local stowed is lexicon().
      local params is cmd:remove(0, "stow-program":length+splitCmd[1]:length+1):trim. //parameter list.
      stowed:add(splitCmd[1], params).
      writejson(stowed, "0:/stowed.json").
      copypath("0:/lib/continue-mission-boot.ks", "1:/boot/continue.ks").
      //compile "0:/lib/continue-mission-boot.ks" to "/boot/continue.ksm".
      set core:bootfilename to "/boot/continue.ks".
      return "finished".
   }
}).

SYS_CMDS:add("run-script", {
   declare parameter cmd.
   if cmd:startswith("run-script") {
      local splitCmd is cmd:split(" ").
      runpath("0:/extra/"+splitCmd[1]+".ks").
      return "finished".
   }
}).