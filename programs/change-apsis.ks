@lazyglobal off.

local programName is "change-apsis". //<------- put the name of the script here
if not (defined kernel_ctl) runpath("0:/lib/core/kernel.ks"). 

kernel_ctl["availablePrograms"]:add(programName, {
//One time initialization code.
  
//======== Imports needed by the program =====
   if not (defined maneuver_ctl) kernel_ctl["import-lib"]("lib/maneuver_ctl").
   if not (defined phys_lib) kernel_ctl["import-lib"]("lib/physics").
   
//======== Parameters used by the program ====
   declare parameter argv.
   local engineName is "".
   local apsis is "".
   local newAlt is "".

   if argv:split(" "):length >= 3 {
      set engineName to argv:split(" ")[0].
      if not (maneuver_ctl["engineDef"](engineName)) return OP_FAIL.
      set apsis to argv:split(" ")[1].
      set newAp to argv:split(" ")[2]:tonumber(ship:orbit:apoapsis).
   } else {
      set kernel_ctl["output"] to
         "Executes a maneuver to raise or lower  ap or pe."
         +char(10)+"   Usage: add-program change-apsis [ENGINE-NAME] ap | pe [ALTITUDE]".
      return.
   }

//======== Local Variables =====
      local steerDir is "retrograde".

//=============== Begin program sequence Definition ===============================
   kernel_ctl["MissionPLanAdd"](programName, {
      until ship:maxthrust < 1.01*maneuver_ctl["engineStat"](engineName, "thrust") and ship:maxthrust > 0.99*maneuver_ctl["engineStat"](engineName, "thrust") {
         kernel_ctl["output"] to "staging, Max thrust: "+ship:maxthrust.
         stage. 
         wait 1.
         if ship:maxthrust > 1.01*maneuver_ctl["engineStat"](engineName, "thrust") or ship:maxthrust < 0.99*maneuver_ctl["engineStat"](engineName, "thrust") {
            set kernel_ctl["output"] to "Maneuver Error: wrong engine".
            return OP_FAIL.
         }
      }
      
      if (apsis = "ap" and ship:orbit:apoapsis > newAlt*0.99 and ship:orbit:apoapsis < newAlt*1.01) or
         (apsis = "pe" and ship:orbit:periapsis > newAlt*0.99 and ship:orbit:periapsis < newAlt*1.01)
         return OP_FINISHED.
      
      if (apsis = "ap" and ship:orbit:apoapsis > newAlt) or
         (apsis = "pe" and ship:orbit:periapsis < newAlt)
         set steerDir to "prograde". 

      local newSMA is phys_lib["sma"](
         ship:orbit:body, 
         choose newAlt if apsis = "ap" else ship:orbit:apoapsis, 
         choose newAlt if apsis = "pe" else ship:orbit:periapsis
      ).
      local newVatApsis is phys_lib["VatAlt"](ship:orbit:body, choose ship:orbit:periapsis if apsis = "ap" else ship:orbit:apoapsis, newSMA).
      local dv is abs(newVatApsis - velocityat(ship, choose eta:periapsis if apsis = "ap" else eta:apoapsis):orbit:mag).

      maneuver_ctl["add_burn"](steerDir, engineName, apsis, dv).

      return OP_FINISHED.
   }).
   kernel_ctl["MissionPLanAdd"](programName, maneuver_ctl["burn_monitor"]).
   kernel_ctl["MissionPLanAdd"](programName, {
      if (apsis = "ap" and ((steerDir = "prograde" and ship:apoapsis < newAlt*0.99 ) or (steerDir = "retrograde" and ship:apoapsis > newAlt*1.01))) or 
         (apsis = "pe" and ((steerDir = "prograde" and ship:periapsis < newAlt*0.99 ) or (steerDir = "retrograde" and ship:periapsis > newAlt*1.01))) {
         if steerDir = "prograde" {
            if vang(ship:facing:forevector, ship:prograde:forevector) > 0.5
               lock throttle to 0.
            wait until vang(ship:facing:forevector, ship:prograde:forevector) < 0.5.
         } else {
            if vang(ship:facing:forevector, ship:retrograde:forevector) > 0.5
               lock throttle to 0.
            wait until vang(ship:facing:forevector, ship:retrograde:forevector) < 0.5.
         }
         lock throttle to 0.1.
         return OP_CONTINUE.
      } else if (apsis = "ap" and ((steerDir = "prograde" and ship:apoapsis > newAlt*1.01) or (steerDir = "retrograde" and ship:apoapsis < newAlt*0.99))) or
                (apsis = "pe" and ((steerDir = "prograde" and ship:periapsis > newAlt*1.01) or (steerDir = "retrograde" and ship:periapsis < newAlt*0.99) {
         if steerDir = "prograde" {
            set steerDir to "retrograde".
         } else {
            set steerDir to "prograde".
         }
         return OP_CONTINUE.
      }
      lock throttle to 0.
      return OP_FINISHED.
   }).
   
         
//========== End program sequence ===============================
   
}). //End of initializer delegate
