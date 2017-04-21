wait 5.
copypath("0:/launch.ks", "").
copypath("0:/include_customlib.ks", "").

global OrbitAltitude is 80000.
global towerHeight is 0.
global pitchOverAngle is 5.

lock progradeVector to ship:srfprograde.
lock progradePitch to 90-vectorangle(up:forevector, progradeVector:forevector).
lock availableAcceleration to ship:availablethrust/ship:mass.

//Throttle
set throttleTable to lexicon().
set throttleTableType to "value".

throttleTable:add(15000, 1).
throttleTable:add(25000, 0.75).
throttleTable:add(40000, 0.5).
throttleTable:add(50000, 0.4).
throttleTable:add(70000, 0.3).
throttleTable:add(OrbitAltitude, 0.1).
throttleTable:add(100000, 0).

set count to 10.
until count < 0 {
   hudtext(count+"...", 1, 2, 20, white, false).
   set count to count -1.
   wait 1.
}
//Inclination, throttleProfile; Type
run launch(0, throttleTable, throttleTableType).