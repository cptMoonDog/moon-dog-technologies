KOS Mission Running System
===========================
A comprehensive system for rapid development and deployment of automated space missions in Kerbal Space Program, using Kerbal Operating System (KOS).
Primarily focused on reducing non-reusable code, while maintaining significant flexibility.

Features
========
 - Rapid launch script development
   - Customize launch profile for each Launch Vehicle
   - Fast and easy Gravity Turns 
   - Linear tangent steering capable
   - Easily target different orbital planes with the same script.
 - Modular, pluggable mission scripting
 
Quickstart
==========
[Example Mission to Minmus Orbit](https://youtu.be/8BtfHxGP5ns)

[Gravity Turn Versus Linear Tangent Steering](https://youtu.be/coE-mWIxKf0)

Launch Vehicles
--------
 1. Make a Launch Vehicle, make sure to include a KOS processor on the upper stage.
 2. Make a copy of `template.ks` in the `lv` directory. 
 3. Edit your new Launch Vehicle definition file, and change any of the the default values to ones appropriate for your launch vehicle.
 4. In the VAB:
    - Set the bootfile for the processor on your launch vehicle to `lv.ks`
    - Set the nameTag of the KOS processor on your launch vehicle to one of the following:
      - `[LAUNCH SCRIPT]                               ` Launch to: equatorial, 80km (default values).
      - `[LAUNCH SCRIPT], [TARGET]                     ` Launch to: coplanar with target at 80km.
      - `[LAUNCH SCRIPT], [INCLINATION], [LAN/RAAN]        ` Launch to: This plane, at 80km.
      - `[LAUNCH SCRIPT], [INCLINATION], [LAN/RAAN], [SMA] ` Launch to: This plane, circularize at this SMA.

Example: Given a craft with a KOS processor named: `Atlas, 6, 78`, and the bootfile `lv.ks`, on launch this ship will run `0:/lv/Atlas.ks` and attempt to launch to an orbit coplanar with Minmus.

Payloads and Missions
--------------------
 1. Make your spacecraft, and make sure to include a KOS processor and a probe core.
 2. In the VAB:
    - Set the bootfile for the KOS processor on the spacecraft to `payload.ks`.
    - Set the nameTag of the KOS processor to `[name you want your ship to have]:[name of mission to run], [mission parameter 1], [mission parameter 2], ... [mission parameter n]`.
 3. Mount your payload to your launch vehicle. The payload will wait until the launch vehicle delivers it to circular orbit and then run it's mission.

Mission Structure
=================
You can put anything you want in a mission file.  When they are called, they are simply run as-is.  However...

They *can* be used to create a list of `programs` to be run in order, to achieve a goal.  The distinction between a `mission` and a `program` is a little fuzzy to say the least, 
but a `program` should be a well defined objective that can be incorporated into a series of objectives, whereas a `mission` should be a sequence of such objectives.

For instance, say you wanted to go to the Mun.  You can write up a mission to the Mun like this:

    //Load programs into memory
    runpath("0:/programs/lko-to-moon.ks").
    runpath("0:/programs/warp-to-soi.ks").
    runpath("0:/programs/powered-capture.ks").

    //Define the sequence in which to run them
    available_programs["lko-to-moon"]("Mun spark").
    available_programs["warp-to-soi"]("Mun").
    available_programs["powered-capture"]("Mun ant").

    //Start running the mission
    kernel_ctl["start"]().

#### What this does:
 1. You have to load each program into memory to make it available to the system.
 2. Then, you define the sequence by actually calling the initializers in the `available_programs` lexicon.  As you can see, these programs require information about the target body, and the engine they will be using at that stage of the mission. ***Programs only accept one string as a parameter***.
 3. Finally, you call the kernel to start running the mission.
    
Standalone Operation
====================
The `runprogram.ks` system is being depreciated.  The prefered system should now be to launch the kernel in interactive mode.  I am calling the system ISH, for "Interactive SHell".  Should fit well with the Kerbal ethic.
To launch the system invoke the following command in the kOS window:

    runpath("0:/lib/core/kernel.ks", true).

Or just:

    runpath("0:/ish.ks").

Commands are still in the process of being implemented, but it is working fairly well.  For instance, you can run a mission with the following commands:

    setup-launch
        Inclination: 45
        LAN: none
        Orbit height: 80000
        Launch Vehicle: Atlas
    add-program change-ap terrier 200000
    start

`setup-launch` will ask you for launch parameters and will add the launch routines to the MISSION_PLAN.
Any `add-program` commands will append their routines for that particular program to the end of the MISSION_PLAN, so you can keep adding items to the running plan, if you want, even in flight.  ~~Be sure to invoke the program correctly, however!  The ISH system cannot verify beforehand if you are giving it the correct number of parameters for the program.  If you give it more or less than the program expects, the system will immediately crash.  This is a known problem, but Jebediah said it was worth the risk, although Werner is still looking for a safer failure mode.~~  As of 11 OCT 2021 programs only accept one string as a parameter, and are responsible for verifying input.

The kernel will not begin running the MISSION_PLAN until you call `start`, but it will remain interactive even while running.  Try running `display altitude` during ascent, for instance.

Libraries
---------
The libraries in `lib` are Scope-Lexicon-Delegate libraries inspired by [gisikw's KNU system.](https://www.youtube.com/watch?v=cqtMpk2GaIY&list=PLb6UbFXBdbCrvdXVgY_3jp5swtvW24fYv&index=44)


Disclaimer
==========
While I have used these routines successfully in my own missions, some may still be in an alpha state.  Use at your own risk.


Updates
=======
This latest update (4 Oct 2021), has involved some fairly major refactoring.  Everything should function generally the same as it has, but paths may have changed, so watch for that.

(11 Oct 2021) Made a policy where programs only accept one string parameter.  This requires some minimal string processing in program definitions, but increases runtime safety; allowing the system to fail safely in the case of spurious user input.
