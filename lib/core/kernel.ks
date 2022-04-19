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

global OP_FAIL is "panic".

global MISSION_PLAN is list().
global INTERRUPTS is list().
global SYS_CMDS is lexicon().

// Kernel Registers
kernel_ctl:add("interactive", interactive).
kernel_ctl:add("status", "ISH: Interactive SHell for kOS").
kernel_ctl:add("countdown", "").
kernel_ctl:add("output", "").
kernel_ctl:add("prompt", ":"). //Prompt



{
   local runmode is 0.

   local time_share is 0.
   local time_count is 0.

   local next_interrupt is 0.
   local inputbuffer is "".
   local cmd_buffer is "".
   local cmd_hist_num is 0.
   local display_buffer is list().

///Public functions
   declare function run {
      until FALSE {
         //Runmodes
         if runmode < MISSION_PLAN:length {
            // Runmode
            set_runmode(MISSION_PLAN[runmode]()).
            if kernel_ctl["interactive"] and terminal:input:haschar process_char(terminal:input:getchar()).
            print kernel_ctl["status"]:padright(terminal:width) at(0, 0).
            print kernel_ctl["countdown"] at(0, 1).
         } else {
            print "end program.".
            break.
         }

         //Interrupts
         if time_count < time_share {
            set time_count to time_count +1.
         } else {
            set time_count to 0.
            if next_interrupt < INTERRUPTS:length {
               INTERRUPTS[next_interrupt]().
               set next_interrupt to next_interrupt +1.
            } else if next_interrupt = INTERRUPTS:length and INTERRUPTS:length > 0 {
               set next_interrupt to 0.
               INTERRUPTS[next_interrupt]().
            }
         }
      }
      set ship:control:pilotmainthrottle to 0.
   }
   set kernel_ctl["start"] to run@.

///Private functions
   declare function set_runmode {
      parameter n.
      if n = OP_FAIL set runmode to MISSION_PLAN:length+100.
      if n >= -1 and n <= 1 set runmode to runmode+n.
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
         if cmd_hist_num <= display_buffer:length set inputbuffer to display_buffer[display_buffer:length - cmd_hist_num].
         else {
            set inputbuffer to "".
            set cmd_hist_num to 0.
         }
      } else if c = terminal:input:DOWNCURSORONE {
         set cmd_hist_num to abs(cmd_hist_num - 1).
         if cmd_hist_num set inputbuffer to display_buffer[display_buffer:length - cmd_hist_num].
         else set inputbuffer to "".
      } else {
         set inputbuffer to inputbuffer + c.
      }
      update_display().
   }

   // Special internal system commands
   SYS_CMDS:add("start", {
      declare parameter cmd.
      set runmode to runmode  + 1.
      return "finished".
   }).

   SYS_CMDS:add("exit", {
      declare parameter cmd.
      set runmode to MISSION_PLAN:length.
      return "finished".
   }).


   declare function process_cmd {
      declare parameter cmd.
      if not(cmd_buffer) {
         display_buffer:add(cmd).
         //If not in the middle of a top-level command
         for token in SYS_CMDS:keys {
            if cmd:trim:tolower:startswith(token) {
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
      local lineNum is 2. // Status and Countdown shown above output area.
      until display_buffer:length < terminal:height - 3 display_buffer:remove(0).
      for s in display_buffer {
         //Prints the start of the line
         if s:length >= terminal:width print s:remove(terminal:width-3, s:length-terminal:width+3)+"..." at(0, lineNum).
         else print s:padright(terminal:width - s:length) at(0, lineNum).
         set lineNum to lineNum + 1.
      }
      print kernel_ctl["prompt"]+ inputbuffer:remove(0, max(0, inputbuffer:length-terminal:width+2)):padright(terminal:width-kernel_ctl["prompt"]:length-1) at(0, terminal:height-1).//prints the end of the line.
      set kernel_ctl["output"] to "".
   }

   if kernel_ctl["interactive"] {
      runoncepath("0:/lib/core/system-cmds.ks").
      clearscreen.
      display_buffer:add("Type:").
      display_buffer:add("   display commands").
      display_buffer:add("         or").
      display_buffer:add("   display programs").
      display_buffer:add("to get started").
      update_display().
      MISSION_PLAN:add({
         return OP_CONTINUE.
      }).

      kernel_ctl["start"]().
   }
   
}
