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
   kernel_ctl:add("output", ""). //Output of last command.
   kernel_ctl:add("error log file", open("0:/errorlog.txt")).
   kernel_ctl:add("log", {
      parameter mesg.
      parameter logto is "error".

      if logto = "error" {
         if not exists("0:/errorlog.txt") {
            create("0:/errorlog.txt"). 
         }
         open("0:/errorlog.txt"):write(mesg).
      } else if logto = "status" {
         if not exists("status") create("status").
         open("status"):clear.
         open("status"):write(mesg).
      }
   }).

   declare function draw_display {
      //Draw a box
      from {local i is 0.} until i = terminal:width-1 step {set i to i+1.} do {print "=" at(i, 0).}
      from {local i is 0.} until i = terminal:width-1 step {set i to i+1.} do {print "=" at(i, terminal:height-2).}
      from {local i is 1.} until i = terminal:height-2 step {set i to i+1.} do {print "|":padright(terminal:width-2)+"|" at(0, i).}

         //Top status line
      from {local i is 1.} until i = terminal:width-2 step {set i to i+1.} do {print "=" at(i, 2).}
      print kernel_ctl["status"] at(1, 1).
      from {local i is 1.} until i = terminal:width-2 step {set i to i+1.} do {print "=" at(i, 4).}
      print kernel_ctl["output"] at(1, 3).
   }


   print prompt at(0, terminal:height-1).
   print cursor at(cur_col, terminal:height-1).

   local command_history_index is command_history:length-1.
   declare function monitor_input {
      draw_display().
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
         set kernel_ctl["output"] to input_string:remove(0, 5).
      } else if cmd_list[0] = "ls" or cmd_list[0] = "dir" {
         list.   
      } else if cmd_list[0] = "runprogram" {
         runpath("0:/programs/"+cmd_list[1]+".ks").
         available_programs[cmd_list[1]](). //appends to the end of the mission plan.
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
