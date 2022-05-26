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
 - Yet, easily customize firmware for any craft!
 - Interactive mode, for those who would rather make the mission plan up as they go along.

 
Videos of it in action
======================
[Launch and deployment of Relays at both moons](https://youtu.be/_q7M74phcO4)

[Example Mission to Minmus Orbit](https://youtu.be/8BtfHxGP5ns)

[Gravity Turn Versus Linear Tangent Steering](https://youtu.be/coE-mWIxKf0)

Quickstart
==========

Set your kOS core boot file to `ish.ks` to start in interactive mode.  Once at the prompt, type `setup-launch` or `display commands` to get an idea how it works.

What follows describes fully automatic mode.

Launch Vehicles
--------
 1. Make a Launch Vehicle, make sure to include a KOS processor on the upper stage.
 2. Make a copy of `template.ks` in the `lv` directory. 
 3. Edit your new Launch Vehicle definition file, and change any of the the default values to ones appropriate for your launch vehicle. (Note: Some may suggest, that this would be an appropriate use for JSON files, but believe it or not Kerboscript is better for human readability.)
 4. In the VAB:
    - Set the bootfile for the processor on your launch vehicle to `lv.ks`
    - You can pass arguments to the script one of two ways:
       - Using the nameTag of the KOS processor on your launch vehicle.
       - Or in the “0:/launchparameters.txt” file under the “//launch” line. This option exists for two reasons, argument strings are often longer than the text box, and it allows the single core to accept responsibility for the “payload.ks” routine, if desired.  See Payloads and Missions for more information.
    - Wherever you set it, the argument string should be one of the following:
      - `[LAUNCH SCRIPT]                               ` Launch to: equatorial, 80km (default values).
      - `[LAUNCH SCRIPT], [TARGET]                     ` Launch to: coplanar with target at 80km.
      - `[LAUNCH SCRIPT], [INCLINATION], [LAN/RAAN]        ` Launch to: This plane, at 80km.
      - `[LAUNCH SCRIPT], [INCLINATION], [LAN/RAAN], [SMA] ` Launch to: This plane, circularize at this SMA.
      - `[LAUNCH SCRIPT], [INCLINATION], [LAN/RAAN], to:[APOAPSIS(km)] ` Launch to: This plane, but do not circularize; Tranfer Orbit to altitude in km.


Example: Given a craft with a KOS processor named: `Atlas, 6, 78`, and the bootfile `lv.ks`, on launch this ship will run `0:/lv/Atlas.ks` and attempt to launch to an orbit with inclination 6 degrees and Longitude of Ascending node 78 degrees which just happens to be coplanar with Minmus.

Payloads and Missions
--------------------
 1. Make your spacecraft, and make sure to include a KOS processor and a probe core.
 2. In the VAB:
    - Set the bootfile for the KOS processor on the spacecraft to `payload.ks`.
       - Note: If the upper stage would be a good choice for the duties of the payload, you have two options:
          - Add a second core to the upper stage and give it the “payload.ks” boot file.
          - Or, if you only want to use the one core, under the “//payload” line in the “0:/launchparameters.txt” file provide the payload arguments.  This will cause the “lv.ks” boot file to directly run the payload boot file rather than send a message to the core that has that boot file.
    - Set the nameTag of the KOS processor to `[name you want your ship to have]:[name of mission to run], [mission parameter 1], [mission parameter 2], ... [mission parameter n]`.
 3. Mount your payload to your launch vehicle. The payload will wait until the launch vehicle delivers it to circular orbit and then run it's mission.

Mission Structure
=================
Update: As of the Spaceman Spiff update, the paradigm for missions has changed.  It is now better to think of
them as your space craft's firmware.  That is, the `payload.ks` boot file will compile the mission file to the core
and assign it as the bootfile before liftoff.  Once the handoff from the booster computer to the payload computer
core is complete, the `payload.ks` boot file will reboot the system, leaving the `mission` in command.

The advantages of this, are that you need not clutter up the `boot` folder with custom boot files for each mission.
The contrast to the old system is that there was not a very well defined difference between `program` and `mission`.
That ambiguity is solved with this new paradigm.

The `payload.ks` bootfile is exclusively intended for use by the PRIMARY core on a payload.  That is, the core that will be doing the driving for the whole ship after booster separation.
If you have, for instance, another craft you will be deploying from this "mothership", use the `mission.ks` bootfile in the VAB.  The `mission.ks` bootfile compiles the mission file to the core
as well, but does not maintain the overhead that the "payload core" needs to.  This allows, for instance, automated satellite constellation deployments, thusly:

If you have a booster, with an `lv.ks` bootfile, it will deliver your payload to orbit.  Then, for instance, your `payload.ks` booted core can be given `mothership-comsat` in the `core:tag` to handle orbit design, and satellite deployment.
Each satellite, given the `mission.ks` bootfile in the VAB, can then be given `deployable-comsat, [NAME], [ENGINE]` in the `core:tag` to handle circularization for themselves and handing the player back off to the "mothership".  If they are ever booted again, they could also be given a section of code intended to orient the solar panels...for instance.

Standalone Operation
====================
The prefered system is to launch the kernel in interactive mode.  I am calling the system ISH, for "Interactive SHell".  Should fit well with the Kerbal mood.
To launch the system invoke the following command in the kOS window:

    runpath("0:/lib/core/kernel.ks", true).

Or just:

    runpath("0:/ish.ks").

Commands are still in the process of being implemented, but it is working fairly well.
For instance, to travel from the launch pad to orbit of the Mun with a launch vehicle named `Atlas` and a `terrier` upper stage engine, type the following:

    setup-launch<ENTER>
    <ENTER>
    <ENTER>
    <ENTER>
    Atlas<ENTER>
    add-program lko-to-moon terrier Mun<ENTER>
    add-program powered-capture terrier Mun<ENTER>
    start

This gives the default values to the launch system, and then adds two programs.  The program should terminate when the spacecraft is in a 200km orbit of the Mun.
    
`setup-launch` will ask you for launch parameters and will add the launch routines to the MISSION_PLAN.
Any `add-program` commands will append their routines for that particular program to the end of the MISSION_PLAN, so you can keep adding items to the running plan, if you want, even in flight.

The kernel will not begin running the MISSION_PLAN until you call `start`, but the command processor will remain interactive even while running.  Try running `display altitude` during ascent, for instance.

Libraries
---------
The libraries are Scope-Lexicon-Delegate libraries inspired by [gisikw's KNU system.](https://www.youtube.com/watch?v=cqtMpk2GaIY&list=PLb6UbFXBdbCrvdXVgY_3jp5swtvW24fYv&index=44)


Disclaimer
==========
While I have used these routines successfully in my own missions, some may still be in an alpha state.  Use at your own risk.


Updates
=======
This latest update (4 Oct 2021), has involved some fairly major refactoring.  Everything should function generally the same as it has, but paths may have changed, so watch for that.

(11 Oct 2021) Made a policy where programs only accept one string parameter.  This requires some minimal string processing in program definitions, but increases runtime safety; allowing the system to fail safely in the case of spurious user input.

(20 May 2022) The Spaceman Spiff update includes internal changes, and improvements to the usability of the `ish` system.

(22 May 2022) We are depreciating the lv_unicore.ks boot script as redundant.  Just add a second core to the upper stage running payload.ks.

Note: I understand and apologize for the inconsistent naming styles, etc you will find.  I have been more concerned with functionality. Maybe someday I will get around to beautification.