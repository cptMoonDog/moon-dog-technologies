@LAZYGLOBAL off.
{
   local input_string is "".
   declare function monitor_input {
      if terminal:input:haschar {
         local car is terminal:input:getchar().
         if car = terminal:input:ENTER {
            process_cmd(). 
            set input_string to "".
         } else {
            print car.
            set input_string to input_string + car.
         }
      }
   }

   declare function process_cmd {
      if input_string = "" {
      }
   }
}
