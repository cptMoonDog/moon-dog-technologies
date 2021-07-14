@LAZYGLOBAL off.
{
   local cur_row is 0.
   local cur_col is 0.
   local cursor is "$".

   local input_string is "".
   declare function monitor_input {
      if terminal:input:haschar {
         local c is terminal:input:getchar().
         if car = terminal:input:ENTER {
            process_cmd(). 
            set input_string to "".
            set cur_row to cur_row + 1.
            set cur_col to 0.
         } else {
            print c at(cur_col, cur_row).
            set cur_col to cur_col + 1.
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
