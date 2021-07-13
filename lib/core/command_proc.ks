@LAZYGLOBAL off.
{
   local input_string is "".
   declare function monitor_input {
      if terminal:input:haschar {
         local c is terminal:input:getchar().
         if car = terminal:input:ENTER {
            process_cmd(). 
            set input_string to "".
         } else {
            print c.
            set input_string to input_string + c.
         }
      }
   }

   //Processes the input command.
   //The command line language is basically defined here.
   declare function process_cmd {
      if input_string = "" {
      } else if input_string = "clear" {
         clearscreen.
      }
   }
}
