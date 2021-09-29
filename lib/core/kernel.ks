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
SYS_CMDS:add("apo", {return ship:apoapsis.}).

// Kernel Registers
kernel_ctl:add("status", "").
kernel_ctl:add("output", "").

kernel_ctl:add("input", "").


{
   local runmode is 0.

   
   local time_share is 0.
   local time_count is 0.

   local next_interrupt is 0.
   local inputbuffer is "".
   local cmd_buffer is "".

   SYS_CMDS:add("mode", {return runmode.}).

///Public functions
   declare function run {
      clearscreen.
      until FALSE {
         //Runmodes
         if runmode < MISSION_PLAN:length {
            // Runmode
            set_runmode(MISSION_PLAN[runmode]()).
            if terminal:input:haschar process_char(terminal:input:getchar()).
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
      } else {
         set inputbuffer to inputbuffer + c.
      }
      update_display().
   }

   declare function process_cmd {
      declare parameter cmd.
      if not(cmd_buffer) {
         if cmd:trim:tolower = "disp apo" {
            set kernel_ctl["output"] to ship:apoapsis.
         } else if cmd:trim:tolower = "add-launch" {
            if ship:status = "PRELAUNCH" {
               runoncepath("0:/lib/launch/launch_ctl.ks").

               set cmd_buffer to cmd:trim:tolower.
               set kernel_ctl["Output"] to "Inclination: ".
            } else {
               set kernel_ctl["output"] to "Not on launch pad".
            }
         }
      } else if cmd_buffer = "add-launch" {
         if kernel_ctl["output"] = "Inclination: " {
            launch_param:add("inclination", cmd:tonumber(0)).
            set kernel_ctl["output"] to "LAN: ".
         } else if kernel_ctl["output"] = "LAN: " {
            if cmd:tonumber(-1) = -1 or launch_param["inclination"] = 0 {
               launch_param:add("lan", "none").
               launch_param:add("launchTime", "now").
            } else {
               launch_param:add("lan", cmd:tonumber(0)).
               launch_param:add("launchTime", "window").
            }
            set kernel_ctl["output"] to "Orbit height: ".
         } else if kernel_ctl["output"] = "Orbit height: " {
            if cmd:tonumber(-1) = -1 launch_param:add("targetApo", 80000).    
            else launch_param:add("targetApo", cmd:tonumber(80000)).    
            set kernel_ctl["output"] to "Launch Vehicle: ".
         } else if kernel_ctl["output"] = "Launch Vehicle: " {
            if exists("0:/lv/"+cmd:trim+".ks") runoncepath("0:/lv/"+cmd:trim+".ks").
            set kernel_ctl["output"] to "".
            set cmd_buffer to "".
         }
      }
   }
            
   declare function update_display {
      print "Status: "+kernel_ctl["status"] at(0, 3).
      //print "Countdown: "+kernel_ctl["countDisplay"] at(0, 4).
      print "Output: "+kernel_ctl["output"] at(0, 5).
      print "Input: "+ inputbuffer:padright(terminal:width-7) at(0, 6).
      print "formatting test" at(0, 7).
   }

   declare function interactive_mode {
      clearscreen.
      print "KOS-Missions Interactive Session".
      print "$:".
      
   }
}
