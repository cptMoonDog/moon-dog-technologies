@LAZYGLOBAL off.
{
   local cur_row is 3.
   local cur_col is 2.
   local prompt is "$ ".
   local cursor is "|".

   local input_string is "".
   local command_history is list().

   //Some status registers
   kernel_ctl:add("status", "Initializing").
   if not exists("0:/errorlog.txt") create("0:/errorlog.txt"). 
   kernel_ctl:add("error log file", open("0:/errorlog.txt")).
   kernel_ctl:add("log", {
      parameter mesg.
      parameter logto is "error".

      if logto = "error" {
         kernel_ctl["error log file"]:writeln(mesg).
      } else if logto = "status" {
         if not exists("status") create("status").
         open("status"):clear.
         open("status"):write(mesg).
      }
   }).


   clearscreen.
   print "KOS-Missions Command Processor v0.0.1 Alpha".
   print "Copyright Year 1 Mikrosoft".
   print prompt at(0, terminal:height-1).
   print cursor at(cur_col, terminal:height-1).

   local command_history_index is command_history:length-1.
   declare function monitor_input {
      if terminal:input:haschar {
         print prompt at(0, terminal:height-1).
         print cursor at(cur_col, terminal:height-1).
         local c is terminal:input:getchar().
         if c = terminal:input:ENTER {
            process_cmd(). 
            command_history:add(input_string).
            set command_history_index to command_history:length.
            set input_string to "".
            set cur_col to 2.
            print prompt:padright(terminal:width-1) at(0, terminal:height-1).
            print cursor at(cur_col, terminal:height-1).
         } else if c = terminal:input:BACKSPACE {
            set input_string to input_string:substring(0, input_string:length-1).
            set cur_col to cur_col -1.
            if cur_col < 2 set cur_col to 2.
            print cursor:padright(terminal:width-prompt:length-input_string:length-1) at(cur_col, terminal:height-1).
         } else if c = terminal:input:UPCURSORONE {
            set input_string to command_history[command_history_index-1].
            set cur_col to (prompt + input_string):length.
            print (prompt + input_string + cursor):padright(terminal:width-1) at(0, terminal:height-1).
            if command_history_index > 0 set command_history_index to command_history_index -1.
         } else if c = terminal:input:DOWNCURSORONE {
            if command_history_index < command_history:length-1 {
               set input_string to command_history[command_history_index+1].
               set command_history_index to command_history_index +1.
            } else set input_string to "".
            set cur_col to (prompt + input_string):length.
            print (prompt + input_string + cursor):padright(terminal:width-1) at(0, terminal:height-1).
         } else {
            print c at(cur_col, terminal:height-1).
            set cur_col to cur_col + 1.
            print cursor at(cur_col, terminal:height-1).
            set input_string to input_string + c.
         }
      }
   }
   kernel_ctl:add("command processor", monitor_input@).

   //Processes the input command.
   //The command line language is basically defined here.
   declare function process_cmd {
      local cmd_list is input_string:split(" ").
      if cmd_list[0] = "" {
      } else if cmd_list[0] = "clear" {
         clearscreen.
      } else if cmd_list[0] = "exit" {
         local index is INTERRUPTS:find(kernel_ctl["command processor"]).
         INTERRUPTS:remove(index).
      } else if cmd_list[0] = "log" {
         log cmd_list[1] to "0:/log.txt".
      } else if cmd_list[0] = "echo" {
         print input_string:remove(0, 5).
      } else if cmd_list[0] = "ls" or cmd_list[0] = "dir" {
         list.
      } else if cmd_list[0] = "display" {
         if cmd_list[1] = "telemetry" {
            INTERRUPTS:add(telemetry_ctl["display"]).
         } else if cmd_list[1] = "status" {
            print open("status"):readall:string.
         } else if cmd_list[1] = "eta:apo" {
            print eta:apoapsis.
         }
      }
   }
}
