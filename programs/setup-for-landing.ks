@lazyglobal off.
// Program Template

local programName is "setup-for-landing". //<------- put the name of the script here

kernel_ctl["availablePrograms"]:add(programName, {
   //One time initialization code.
   //   Question: Why not simply have a script file with the contents of the initializer delegate?  Why the extra layers?
   //   Answer: It seems that the memory area for parameters passed to scripts is always the same.  So, when 
   //           a script defines a function to be called later, any additional script called with parameters will
   //           clobber the parameter intended for the first one.  The parameter below will be preserved and its value
   //           will remain available to the program, as long as the program is written within this scope, 
  
//======== Imports needed by the program =====
   if not (defined maneuver_ctl) kernel_ctl["import-lib"]("lib/maneuver_ctl").
   if not (defined phys_lib) kernel_ctl["import-lib"]("lib/physics").
   
//======== Parameters used by the program ====
   declare parameter argv.
   local engineName is "".
   local targetObject is "".
   local tgtLat is -1.
   local tgtLon is -1.
   local vecsDrawn is false.
   local nodeCreated is false.
   if argv:split(" "):length >= 2 {
      set engineName to argv:split(" ")[0].
      if not (maneuver_ctl["engineDef"](engineName)) return OP_FAIL.
      if argv:split(char(34)):length > 1 set targetObject to argv:split(char(34))[1]. // Quoted second parameter
      else set targetObject to argv:split(" ")[1].
      if targetObject:contains(":"){
         set tgtLat to targetObject:split(":")[0]:toscalar(0).
         set tgtLon to targetObject:split(":")[1]:toscalar(0).
      }
      set kernel_ctl["output"] to "target: "+ targetObject.
      clearvecdraws().
   } else {
      set kernel_ctl["output"] to
         "Creates and executes a maneuver to match an orbit which overflys a given position on the surface."
         +char(10)+"Usage: Q setup-for-landing [ENGINE-NAME] [LAT]:[LON]".
      return.
   }

//======== Local Variables =====

//=============== Begin program sequence Definition ===============================
   // The actual instructions implementing the program are in delegates, Which the initializer adds to the MISSION_PLAN.
   // In this case, the first part of the program sequence
   // is given as an anonymous function, and the second part is a function implemented in the maneuver_ctl library. 
   // If you do not like anonymous functions, you could implement a named function elsewhere and add a reference
   // to it to the MISSION_PLAN instead, like so: kernel_ctl["MissionPlanAdd"](named_function@).
   kernel_ctl["MissionPlanAdd"](programName, {
      if tgtLat = -1 {
         set target to targetObject.
         set tgtLat to target:geoposition:LAT.
         set tgtLon to target:geoposition:LNG.
      }
      local shipRate is 360/ship:orbit:period.
      local tgtRate is 360/ship:body:rotationperiod.

      local tgtSOIVector is ship:body:geopositionlatlng(tgtLat, tgtLon):position - ship:body:position.
      local tgtLANVector is vcrs(tgtSOIVector:normalized, ship:body:angularvel:normalized).

      local myLANVector is phys_lib["lanVector"](ship).
      local tgtLAN is vang(solarprimevector, tgtLANVector).
      local tgtInc is tgtLat.
      local overflightOrbit is createOrbit(tgtInc, 0, ship:orbit:semimajoraxis, tgtLAN, 0, 0, 0, ship:orbit:body).

      local myPlane is vcrs(-ship:body:position, myLANVector).

      local theirPlane is vcrs(tgtSOIVector, tgtLANVector).
      local AN_DN is vcrs(myPlane, theirPlane):normalized.
      if not(vecsDrawn) {
      set vecsDrawn to true.
      local tgtVect is vecdraw(
                            {return ship:body:position.}, 
                            {return AN_DN*ship:body:radius.},
                            RGB(1, 1, 0),
                            "Target",
                            10,
                            true,
                            0.01,
                            true,
                            true).
      local tgtLANVect is vecdraw(
                            {return ship:body:position.}, 
                            {return tgtLANVector*ship:body:radius.},
                            RGB(1, 0, 1),
                            "Target",
                            10,
                            true,
                            0.01,
                            true,
                            true).
      local myLANvec is vecdraw(
                            {return ship:body:position.}, 
                            {return myLANVector*ship:body:radius.},
                            RGB(0, 1, 1),
                            "My Plane",
                            10,
                            true,
                            0.01,
                            true,
                            true).
      local test2 is vecdraw(
                            {return ship:body:position.}, 
                            {return myPlane*ship:body:radius.},
                            RGB(0, 1, 0),
                            "My Plane",
                            10,
                            true,
                            0.01,
                            true,
                            true).
      local test3 is vecdraw(
                            {return ship:body:position.}, 
                            {return theirPlane*ship:body:radius.},
                            RGB(0, 0, 1),
                            "Their Plane",
                            10,
                            true,
                            0.01,
                            true,
                            true).
      }
      local dInc is vang(myPlane, theirPlane).
      if dInc > 90 set dInc to 180-dInc.
      print "Relative Inclination: "+dInc at(0, 15).

      local angleToANDNNode is vang(up:forevector, AN_DN).  //Great, but am I coming or going?
      print "angle to BP: "+angleToANDNNode at(0, 16).
      local velAngleToANDNNode is vang(ship:prograde:forevector, AN_DN).
      print "Velocity angle to BP: "+angleToANDNNode at(0, 17).
      if velAngleToANDNNode < 90 set angleToANDNNode to vang(up:forevector, AN_DN). // Heading toward, and this should give less than 180 degrees.
      else set angleToANDNNode to 180-angleToANDNNode.  // Should switch it to the other direction
      print "Computed angle to BP: "+angleToANDNNode at(0, 18).
      
      local minEtaBP is (angleToANDNNode)*((ship:orbit:period)/360).
      print "eta BP: "+minEtaBP at(0, 19).

      local dvNormal is ship:velocity:orbit:mag*sin(dInc).
      local dvPrograde is ship:velocity:orbit:mag*cos(dInc) - ship:velocity:orbit:mag.
      if ship:orbit:inclination > 90 set dvNormal to -dvNormal.
      if not(nodeCreated) {
         add(node(time:seconds+minEtaBP, 0, dvNormal, dvPrograde)).
         set nodeCreated to true.
      }

      return OP_CONTINUE.
      //maneuver_ctl["add_burn"]("node", engineName, "node", nextnode:deltav:mag).
      return OP_FINISHED.
   }).
   kernel_ctl["MissionPlanAdd"](programName, maneuver_ctl["burn_monitor"]).
         
//========== End program sequence ===============================
   
}). //End of initializer delegate
