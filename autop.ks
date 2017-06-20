//James McConnel
//yehoodig@gmail.com
//Autopilot for airplanes in Kerbal Space Program
//Currently allows for maintaining heading, speed and altitude.
//Also allows for terminal user input: Cursor keys shift heading
//left and right.
//V{number} sets vertical speed setpoint
//A{number} sets altitude setpoint
//S{number} sets speed setpoint 
//and 
//L{number} sets pitch limit
declare parameter h is 90.0.
declare parameter speedSP is 300.0.
declare parameter altSP is 20000.0.
declare parameter vSpeedSP is 0.

set tPID to PIDLOOP(1, 0.1, 1).
set tPID:maxOutput to 1.
set tPID:minOutput to 0.
set tPID:setpoint to speedSP. 

set pPID to PIDLOOP(1, 0, 1).
set pitchLimiter to 10.
set pPID:maxOutput to pitchLimiter.
set pPID:minOutput to -pitchLimiter.
set pPID:setpoint to altSP. 
 
set thrott to 1.
set p to 0.
lock steering to heading(h, p).

when ship:control:pilotyaw then {
   if ship:control:pilotyaw > 0 headingRight().
   else headingLeft().
   preserve.
}
lock throttle to tPID:update(time:seconds, ship:airspeed).
clearscreen.
print "Command: ".
local SP is ship:altitude.
lock p to pPID:update(time:seconds, SP). 
local command is "".
local numStr is "".
until false {
  if vSpeedSP = 0 {
     //Mode 1: Control Altitude and Speed
     set SP to ship:altitude.
  }else{
     //Mode 2: Control rate of Descent/Ascent
     set SP to ship:verticalSpeed.
  }
  if terminal:input:haschar() {
     local ch is terminal:input:getchar().
     if ch = terminal:input:rightcursorone {
        headingRight().
     } else if ch = terminal:input:leftcursorone {
        headingLeft().
     }else {
        if command:length {
           if ch = terminal:input:RETURN {
              parseCommand(command, numStr).
              set command to "".
              set numStr to "".
              clearscreen.
              print "Command: ".
           } else {
              set numStr to numStr+ch.
              print ch at(0, 9+numStr:length).
           }
        } else {
           set command to ch.
           print ch at(0, 9).
        }
        
     }
     wait 0.01.
  }
}
declare function headingRight {
  set h to h+1.
  if h >= 360 set h to 0.
}
declare function headingLeft {
  set h to h-1.
  if h < 0 set h to 359.
}
declare function parseCommand {
   parameter command.
   parameter numStr.
   if command:toupper = "V" {
      set vSpeedSP to numStr:toNumber(vSpeedSP).
      if vSpeedSP = 0 {
         //Mode 1: Control Altitude and Speed
         set pPID:setpoint to altSP.
         set SP to ship:altitude.
      }else {
         //Mode 2: Control rate of Descent/Ascent
         set pPID:setpoint to vSpeedSP. 
         set SP to ship:verticalSpeed.
      }
   }else if command:toUpper = "A" {
      set altSP to numStr:toNumber(altSP).
      if vSpeedSP = 0 {
         //Mode 1: Control Altitude and Speed
         set pPID:setpoint to altSP.
         set SP to ship:altitude.
      }else {
         //Mode 2: Control rate of Descent/Ascent
         set pPID:setpoint to vSpeedSP. 
         set SP to ship:verticalSpeed.
      }
   }else if command:toUpper = "S" {
      set speedSP to numStr:toNumber(speedSP).
      set tPID:setpoint to speedSP. 
   }else if command:toUpper = "L" {
      set pitchLimiter to numStr:toNumber(pitchLimiter).
      set pPID:maxOutput to pitchLimiter.
      set pPID:minOutput to -pitchLimiter.
   }
}
