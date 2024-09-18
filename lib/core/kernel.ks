// "Kernel" for KOS:
//  A system for managing runmodes

//  Run mode (e.g. Current state of ship)
//     Major mission events, reaction to.
//     Runmodes defined as scoped sections exposing a subroutine that does the work.
//     Subroutine returns integer indicating whether to advance, retreat, or loop. 
//  Interrupts
//     Allows for semi-concurrent execution.  Each subroutine is executed continously.
//     Good for reacting to user input.
@LAZYGLOBAL OFF.
declare parameter interactive is false.

global kernel_ctl is lexicon().

global OP_FINISHED is 1.
global OP_CONTINUE is 0.
global OP_PREVIOUS is -1.

global OP_FAIL is 32767.

local MISSION_PLAN is list().
local MISSION_PLAN_ID is list().
local MISSION_PLAN_ABORT is list(). // Potential to allow programs and missions to have abort modes.

global SYS_CMDS is lexicon().
global SYS_CMDS_HELP is lexicon().

kernel_ctl:add("availablePrograms", lexicon()).

// Kernel Registers
kernel_ctl:add("interactive", interactive).
if(interactive) kernel_ctl:add("status", "ISH: Interactive SHell for kOS").
else kernel_ctl:add("status", "Moon Dog Technologies").
kernel_ctl:add("countdown", "").
kernel_ctl:add("output", "").
kernel_ctl:add("prompt", ":"). //Prompt



clearscreen.
{
   local runmode is 0.

   local inputbuffer is "".
   local cmd_buffer is "".
   local cmd_history is list().
   local cmd_hist_num is 0.
   local display_buffer is list().
   local lagTime is time:seconds.

///Public functions
   declare function start {
      until FALSE {
         // Execute current routine
         if runmode < MISSION_PLAN:length and runmode >= -1 {
            set lagTime to time:seconds.
            set_runmode(MISSION_PLAN[runmode]()).

            // If mission plan is still running...
            local seperator is "".
            set seperator to seperator:padright(terminal:width):replace(" ", "-").
            print seperator at(0, 2).
            if kernel_ctl["output"] {
               if kernel_ctl["output"]:istype("String") for s in kernel_ctl["output"]:split(char(10)) display_buffer:add(s).
               else display_buffer:add(kernel_ctl["output"]:tostring).
               set kernel_ctl["output"] to "".
               update_display().
            }
            if kernel_ctl["interactive"] {
               print kernel_ctl["status"]:tostring:padright(terminal:width) at(0, 0).
               print kernel_ctl["countdown"]:padright(terminal:width) at(0, 1).
               if terminal:input:haschar process_char(terminal:input:getchar()).
            } else{
               print kernel_ctl["status"]:tostring:padright(terminal:width) at(0, 0).
               print kernel_ctl["countdown"]:padright(terminal:width) at(0, 1).
            }
            set lagTime to ((time:seconds - lagTime)*1000):tostring:split(".")[0].
            // Core ipu throttle.  Improves User experience in interactive mode.
            if lagTime:tonumber(-1) > 20 set config:ipu to min(2000, config:ipu+100).
            else if config:ipu > 150 set config:ipu to max(150, config:ipu-1).
            //set kernel_ctl["countdown"] to "".
         } else {
            if kernel_ctl["interactive"]  and runmode = MISSION_PLAN:length { 
               // Resets the mission plan, so we can stay Alive.
               set runmode to 0.
               until MISSION_PLAN:length = 1 {
                  display_buffer:add("removing: "+MISSION_PLAN_ID[0]).
                  MISSION_PLAN:remove(1).
                  MISSION_PLAN_ID:remove(0).
               }
               print kernel_ctl["status"]:padright(terminal:width) at(0, 0).
               set kernel_ctl["status"] to "Mission Complete".
               set ship:control:pilotmainthrottle to 0.
               unlock throttle.
               unlock steering.
            } else {
               print "System Terminated" at(0, 0).
               break.
            }
         }

      }
      set ship:control:pilotmainthrottle to 0.
   }
   set kernel_ctl["start"] to start@.

   declare function default_abort {
      set kernel_ctl["status"] to "!!!WARNING!!! !!!WARNING!!!".
      display_buffer:add("!!!WARNING!!!"+char(10)).
      display_buffer:add("NO ABORT MODE DEFINED"+char(10)).
      update_display().
      return OP_FINISHED.
   }
   declare function MPadd {
      declare parameter name.
      declare parameter delegate.
      declare parameter abort is default_abort@.
      
      MISSION_PLAN:add(delegate). 
      MISSION_PLAN_ID:add(name).
      MISSION_PLAN_ABORT:add(abort).
   }
   set kernel_ctl["MissionPlanAdd"] to MPadd@.
   
   declare function MPremove {
      declare parameter id.
      
      if MISSION_PLAN_ID:length {
         if MISSION_PLAN:length > MISSION_PLAN_ID:length { // Interactive mode
            // In interactive mode, item 0 just keeps the system alive.
            // The remove command in ISH will give a number one less than the program to terminate.
            if id:istype("Scalar") and id < MISSION_PLAN_ID:length {
               MISSION_PLAN:remove(id+1).
               MISSION_PLAN_ID:remove(id).
               MISSION_PLAN_ABORT:remove(id).
            } else { // Remove by name 
               until MISSION_PLAN_ID:find(id) < 0 {
                  local lowestIdOfName is MISSION_PLAN_ID:find(id). 
                  MISSION_PLAN:remove(lowestIdOfName+1).
                  MISSION_PLAN_ID:remove(lowestIdOfName).
                  MISSION_PLAN_ID:remove(lowestIdOfName).
               }
               print MISSION_PLAN_ID:find(id) at(0, 10).
            }
         } else {
            MISSION_PLAN:remove(id).
            MISSION_PLAN_ID:remove(id).
            MISSION_PLAN_ABORT:remove(id).
         }
      }
   }
   set kernel_ctl["MissionPlanRemove"] to MPremove@.

   declare function MPinsert {
      parameter id.
      parameter name.
      parameter delegate.
      parameter abort is {}.
 
      MISSION_PLAN:insert(id, delegate).
      MISSION_PLAN_ID:insert(id, name).
      MISSION_PLAN_ID:insert(id, abort).
   }
   set kernel_ctl["MissionPlanInsert"] to MPinsert@.

   declare function MPids {
      return MISSION_PLAN_ID.
   }
   set kernel_ctl["MissionPlanList"] to MPids@.

   // This is intended to make it easier to work with scripts loaded to the core.
   declare function import_lib {// Load the file, without needing to know where it is, search the core first.
      parameter name.
      if exists("1:/"+name+".ksm") {        // Prefer compiled to the core
         runoncepath("1:/"+name+".ksm").
      } else if exists("1:/"+name+".ks") {  // Second choice uncompiled on the core
         runoncepath("1:/"+name+".ks").
      } else if exists("0:/"+name+".ks") {  // Third choice on the archive
         runoncepath("0:/"+name+".ks").
      }
   }
   set kernel_ctl["import-lib"] to import_lib@.

   // Runs the initializer for named program, adding as the next item in the MISSION_PLAN
   declare function add_program {
      parameter name.
      parameter parameters.
      set kernel_ctl["status"] to "program added with param: "+name+parameters.
      if kernel_ctl["availablePrograms"]:haskey(name) {
         kernel_ctl["availablePrograms"][name](parameters).
      } else {
         set kernel_ctl["status"] to "Program: "+name+" does not exist".
         set kernel_ctl["status"] to kernel_ctl["availablePrograms"].
      }
   }
   set kernel_ctl["add-program"] to add_program@.
   set kernel_ctl["add"] to add_program@.
   set kernel_ctl["Q"] to add_program@.

   declare function loadToCore {
      parameter name.
      if exists("0:/"+name+".ks") compile "0:/"+name+".ks" to "1:/"+name+".ksm".
   }
   set kernel_ctl["load-to-core"] to loadToCore@.
   
   // Alpha, kinda sorta works...
   declare function hibernation_wake {
      import_lib("missions/"+core:tag).
      set runmode to open("1:/hiberfile"):readall:string:tonumber(0).
   }
   set kernel_ctl["wakeup"] to hibernation_wake@.  

///Private functions
   declare function set_runmode {
      parameter n.
      if n = OP_FAIL {
         print "runmode: "+runmode.
         print MISSION_PLAN_ID[runmode] + " returned fail flag.".
         set MISSION_PLAN to MISSION_PLAN:sublist(0, runmode+1).
         set MISSION_PLAN_ID to MISSION_PLAN:sublist(0, runmode).
         MISSION_PLAN_ID:add("abort").
         MISSION_PLAN:add(MISSION_PLAN_ABORT[runmode]).
         set runmode to runmode+1.
      }
      if n >= -1 and n <= 1 set runmode to runmode+n.
      // Hibernation.  Alpha, kinda sorta works...
      if n and exists("1:/hiberfile") {
         local hib is open("1:/hiberfile").
         hib:clear.
         hib:writeln(runmode).
      } 
      if runmode >= MISSION_PLAN:length or runmode < 0 {
         print "MISSION_PLAN index out of range: "+runmode.
         print "n: "+n.
      }
   }

   declare function process_char {
      declare parameter c.
      if c = terminal:input:ENTER {
         process_cmd(inputbuffer).
         set inputbuffer to "".
         set cmd_hist_num to 0.
      } else if c = terminal:input:BACKSPACE {
         if inputbuffer:length > 0 set inputbuffer to inputbuffer:substring(0, inputbuffer:length-1).
      } else if c = terminal:input:UPCURSORONE {
         set cmd_hist_num to cmd_hist_num + 1.
         if cmd_hist_num <= cmd_history:length set inputbuffer to cmd_history[cmd_history:length - cmd_hist_num].
         else {
            set inputbuffer to "".
            set cmd_hist_num to 0.
         }
      } else if c = terminal:input:DOWNCURSORONE {
         set cmd_hist_num to abs(cmd_hist_num - 1).
         if cmd_hist_num set inputbuffer to cmd_history[cmd_history:length - cmd_hist_num].
         else set inputbuffer to "".
      } else {
         set inputbuffer to inputbuffer + c.
      }
      update_display().
   }

   // Special internal system commands
   SYS_CMDS_HELP:add("engage", char(10)+"Starts running the Mission Plan").
   SYS_CMDS_HELP:add("start", char(10)+"Alias for 'engage'").
   declare function start_system {
      declare parameter cmd.
      set runmode to runmode  + 1.
      return "finished".
   }
   SYS_CMDS:add("engage", start_system@).
   SYS_CMDS:add("start", start_system@).

   SYS_CMDS_HELP:add("abort",
      char(10)+
      "Aborts the Mission"+char(10)+
      "   Usage: abort [OPTION]"+char(10)+
      "   Default: Runs the abort routine for this mission_plan item and"+char(10)+
      "            skips all remaining mission elements"+char(10)+
      "   -c | --clear  clears the mission-plan"+char(10)+
      "   -r | --reboot  Reboots the system"+char(10)+
      "   -s | --shutdown Off switch"
   ).
   SYS_CMDS:add("abort", {
      declare parameter cmd.
      local splitCmd is cmd:split(" ").
      if splitCmd:length > 1 {
         if splitCmd[1] = "-r" OR splitCmd[1] = "--reboot" reboot.
         else if splitCmd[1] = "-s" OR splitCmd[1] = "--shutdown" shutdown.
         else if splitCmd[1] = "-c" OR splitCmd[1] = "--clear" {
            set MISSION_PLAN to MISSION_PLAN:sublist(0, 1).  // If this gets called we are in interactive mode.
            set MISSION_PLAN_ID to list().
            set MISSION_PLAN_ABORT to list().
            set runmode to 0.
         }
      } else {
         set MISSION_PLAN to MISSION_PLAN:sublist(0, runmode+1).
         set MISSION_PLAN_ID to MISSION_PLAN:sublist(0, runmode).
         MISSION_PLAN_ID:add("abort").
         MISSION_PLAN:add(MISSION_PLAN_ABORT[runmode]).
         set runmode to runmode+1.
      }
      return "finished".
   }).

   SYS_CMDS_HELP:add("clear", char(10)+"Clears the screen").
   SYS_CMDS:add("clear", {
      declare parameter cmd.
      display_buffer:clear().
      clearscreen.
      return "finished".
   }).


   declare function process_cmd {
      clearscreen.
      declare parameter cmd.
      if not(cmd_buffer) {
         display_buffer:add(cmd).
         cmd_history:add(cmd).
         if cmd_history:length > 100 cmd_history:remove(0).
         //If not in the middle of a top-level command
         for token in SYS_CMDS:keys {
            if cmd:trim:tolower:startswith(token:trim:tolower) {
               // This triggers the secondary input system
               set cmd_buffer to token.
               if SYS_CMDS[cmd_buffer](cmd:trim) = "finished" {
                  if kernel_ctl["output"]:istype("String") for s in kernel_ctl["output"]:split(char(10)) display_buffer:add(s).
                  else display_buffer:add(kernel_ctl["output"]:tostring).
                  set cmd_buffer to "".
                  set kernel_ctl["prompt"] to ":".
               }
               return.
            }
         }
         display_buffer:add("No such command").
      } else {
         set kernel_ctl["output"] to "".
         if SYS_CMDS[cmd_buffer](cmd) = "finished" {
            set cmd_buffer to "".
            set kernel_ctl["prompt"] to ":".
         }
         if kernel_ctl["output"] display_buffer:add("   "+kernel_ctl["output"]:tostring).
      }
   }
            
   declare function update_display {
      local lineNum is 3. // Status and Countdown shown above output area.
      if kernel_ctl["status"] AND display_buffer[display_buffer:length-1] = kernel_ctl["status"] {
         display_buffer:add(kernel_ctl["status"]).
      }
      until display_buffer:length < terminal:height - 4 display_buffer:remove(0).
      for s in display_buffer {
         //Prints the start of the line
         if s:length >= terminal:width print s:remove(terminal:width-3, s:length-terminal:width+3)+"..." at(0, lineNum).
         else print s:padright(terminal:width - s:length) at(0, lineNum).
         set lineNum to lineNum + 1.
      }
      print kernel_ctl["prompt"]+ inputbuffer:remove(0, max(0, inputbuffer:length-terminal:width+2)):padright(terminal:width-kernel_ctl["prompt"]:length-1) at(0, terminal:height-1).//prints the end of the line.
      set kernel_ctl["output"] to "".
   }

   // Starts interactive mode
   if kernel_ctl["interactive"] {
      runoncepath("0:/lib/core/system-cmds.ks").
      clearscreen.
      display_buffer:add("To get started").
      display_buffer:add("Type:").
      display_buffer:add("   help").
      update_display().
      MISSION_PLAN:add({
         return OP_CONTINUE.
      }).

      kernel_ctl["start"]().
   }
   
}
