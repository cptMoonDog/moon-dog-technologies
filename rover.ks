parameter setSpeed is 5.
until false {
   if ship:velocity:surface:mag < setSpeed -0.01 {
      if wheelthrottle = 0 lock wheelthrottle to 1.
      if brakes brakes off.
   } else if ship:velocity:surface:mag > setSpeed +0.01 {
      if wheelthrottle > 0 lock wheelthrottle to 0.
      if not brakes brakes on.
   }
}
