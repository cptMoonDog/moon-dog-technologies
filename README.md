KOS Mission Running System
===========================
A comprehensive system for rapid development and deployment of automated space missions in Kerbal Space Program, using Kerbal Operating System (KOS).
Primarily focused on reducing non-reusable code, while maintaining significant flexibility.

Features
========
 - Rapid launch script development
   - FULLY customize launch profile for each Launch Vehicle
   - Fast and easy Gravity Turns 
   - Easily target different orbital planes with the same script.
 - Modular, pluggable mission scripting
 
Quickstart
==========

Launch Vehicles
--------
 1. Make a Launch Vehicle, make sure to include a KOS processor, with the bootfile `lv_boot.ks`(on the upperstage) and a probe core.
 2. Make a copy of `template.ks` in the `lv` directory. Name it using the following format: [VEHICLE NAME].ks
 3. Edit your new Launch Vehicle definition file, and change any of the the default values to ones appropriate for your launch vehicle.
 4. In the VAB:
    - Set the bootfile for your launch vehicle to `lv_boot.ks`
    - Set the nameTag of the KOS processor on your launch vehicle to one of the following:
      - `[VEHICLE NAME]                               ` Launch to: equatorial, 80km (default values).
      - `[VEHICLE NAME], [TARGET]                     ` Launch to: coplanar with target at 80km.
      - `[VEHICLE NAME], [INCLINATION], [RAAN]        ` Launch to: This plane, at 80km.
      - `[VEHICLE NAME], [INCLINATION], [RAAN], [SMA] ` Launch to: This plane, circularize at this SMA.

Example: Given a craft with a KOS processor named: `Atlas, 6, 78`, and the bootfile `lv_boot.ks`, on launch this ship will run `0:/lv/Atlas.ks' and attempt to launch to an orbit coplanar with Minmus.

Payloads and Missions
--------------------
 1. Make your spacecraft, and make sure to include a KOS processor and a probe core.
 2. In the VAB:
    - Set the bootfile for the KOS processor on the spacecraft to `payload_boot.ks`.
    - Set the nameTag of the KOS processor to [name you want your ship to have]:[name of mission to run].
 3. Mount your payload to your launch vehicle. The payload will wait until the launch vehicle delivers it to circular orbit and then run it's mission.

Mission Structure
=================
You can put anything you want in a mission file.  When they are called, they are simply run as-is.  However...

They *can* be used to create a list of `programs` to be run in order, to achieve a goal.  For instance, say you wanted to go to the Mun.  You can write up a mission to the Mun like this:

    //Load programs into memory
    runpath("0:/programs/lko-to-moon.ks").
    runpath("0:/programs/warp-to-soi.ks").
    runpath("0:/programs/powered-capture.ks").

    //Define the sequence in which to run them
    available_programs["lko-to-moon"]("Mun", "spark").
    available_programs["warp-to-soi"]("Mun").
    available_programs["powered-capture"]("Mun", "ant").

    //Start running the mission
    kernel_ctl["start"]().

#### What this does:
 1. You have to load each program into memory to make it available to the system.
 2. Then, you define the sequence by actually calling the initializers in the `available_programs` lexicon.  As you can see, these programs require information about the target body, and the engine they will be using at that stage of the mission.
 3. Finally, you call the kernel to start running the mission.
    
Standalone Operation
====================
Programs may be invoked individually.  Unfortunately, the overhead required to make them compatible with the sequencing system makes invoking them more complicated than simply running the file.  Therefore, `runprogram.ks` is provided.  You may invoke individual programs at the KOS terminal in the following manner:

    runpath("0:/runprogram.ks", [PROGRAM NAME], list([PARAMETER1], [PARAMETER2], [PARAMETER n])).
    
For more information about extending the system and technical details, see the wiki.  (A work in progress).

Libraries
---------
The libraries in `lib` are Scope-Lexicon-Delegate libraries inspired by [gisikw's KNU system.](https://www.youtube.com/watch?v=cqtMpk2GaIY&list=PLb6UbFXBdbCrvdXVgY_3jp5swtvW24fYv&index=44)


Disclaimer
==========
While I have used these routines successfully in my own missions, some may still be in an alpha state.  Use at your own risk.
   



