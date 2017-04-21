
until FALSE {
   if TRUE {
      test2().
   }
}
{
   local num is 0.
   declare function test1 {
      print num.
      set num to num+1.
   }
   global test2 is test1@.
}
