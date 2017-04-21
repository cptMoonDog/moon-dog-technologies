if ship:periapsis > 70000 { 
   lock steering to retrograde.
   wait 5.
   lock throttle to 1.
   wait until ship:periapsis <= 35000.
   lock throttle to 0.
   wait 5.
   lock steering to retrograde*R(90, 0, 0).
   wait 5.
   stage.
   wait 3.
   lock steering to retrograde.
   wait until ship:airspeed < 270.
   stage.
   set ship:control:pilotmainthrottle to 0.
} else {
   copypath("0:/ascent/throttleControl.ks", "").
   copypath("0:/ascent/steeringControl.ks", "").
   copypath("0:/ascent/stagingControl.ks", "").
   copypath("0:/maneuver.ks", "").
   wait 3.
   run throttleControl(lexicon("altitude", list(20000, 40000, 50000, 60000, 70000, 80000), 
                               "throttle", list(    1,  0.75,   0.5,   0.25,   0.25, 0.25))).
   run steeringControl(80000, 0, 4, 35, 125).
   run stagingControl.
   launch().
   install_genStaging().
   steeringProgram().
   when ship:altitude > 60000 then AG1 ON.
   wait until ship:apoapsis >= 80000 AND ship:altitude > 70000.
   if stage:liquidfuel < 10 {stage. wait 1.}.
   set velAtApo to sqrt(Kerbin:mu*(2/(ship:apoapsis+Kerbin:radius) - 1/(ship:orbit:semimajoraxis))).
   set OVatAPO to Kerbin:radius*sqrt(9.80665/(Kerbin:radius+ship:apoapsis)).
   run maneuver(time:seconds+eta:apoapsis, OVatApo - velAtApo, 345, 17.73419501). 
   wait until ship:periapsis >= 80000.
   set ship:control:pilotmainthrottle to 0.
   sas on.
}


