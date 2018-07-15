KOS Mission Running System
===========================
A comprehensive system for rapid development and deployment of automated space missions in Kerbal Space Program, using Kerbal Operating System (KOS).
Primarily focused on reducing non-reusable code, while maintaining significant flexibility.

Features
========
 - Rapid Launcher Family development and optimization
 - Efficient, fully customizable Gravity Turns
 - Modular, pluggable mission development
 
Quickstart
==========

Boosters
--------
 1. Make a booster, make sure to include a KOS processor and a probe core.
 2. Make a copy of `template.ks` in the `lv` directory. Name it for your new booster.
 3. Edit your new Launch Vehicle definition file.  Change the default values to ones appropriate for your booster.
    - Ex. pitchover magnitude, pitchover start velocity, throttle program type to use, etc...
 4. In the VAB:
    - Set the bootfile for your booster to `lv_boot.ks`
    - Set the nameTag of the KOS processor on your booster to the name of your Launch Vehicle definition file.  E.g. if the file is Atlas.ks, set the nameTag of your booster's KOS part to Atlas.
 5. That's it for the booster!  Just mount a payload, press launch, and watch your rocket deliver your payload to LKO!

Payloads and Missions
--------------------
 1. Make your spacecraft, and make sure to include a KOS processor and a probe core.
 2. In the VAB:
    - Set the bootfile for the KOS processor on the spacecraft to `payload_boot.ks`.
    - Set the nameTag of the KOS processor to [name you want your ship to have]:[name of mission to run].
 3. Mount your payload to your booster. The payload will wait until the launch vehicle delivers it to LKO and then run it's mission.

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
    
### Writing Additions to the `MISSION_PLAN`
You can also add your own routines to the mission sequence in the following way:

    MISSION_PLAN:add({
       print "waiting...".
       wait until ship:orbit:body = body("Mun").
       print "finished waiting...".
       return OP_FINISHED.
    }).

#### Return values tell the kernel how to behave.

 * `OP_CONTINUE` tells the kernel to run this function again.
 * `OP_FINISHED` tells the kernel to advance to the next function in the `MISSION_PLAN`.
 * `OP_PREVIOUS` tells the kernel to go back to the previous function in the `MISSION_PLAN`.
 * `OP_FAIL`     tells the kernel to panic and quit.

Standalone Operation
====================
Programs may be invoked individually.  Unfortunately, the overhead required to make them compatible with the sequencing system makes invoking them more complicated than simply running the file.  Therefore, `runprogram.ks` is provided.  You may invoke individual programs at the KOS terminal in the following manner:

    runpath("0:/runprogram.ks", [PROGRAM NAME], list([PARAMETER1], [PARAMETER2], [PARAMETER n])).
    
Extending the System
====================
Programs
--------
Describing the structure of program files is beyond the scope of this document.  For information about how to build them, see the examples provided.  

Libraries
---------
The libraries in `lib` are Scope-Lexicon-Delegate libraries inspired by [gisikw's KNU system.](https://www.youtube.com/watch?v=cqtMpk2GaIY&list=PLb6UbFXBdbCrvdXVgY_3jp5swtvW24fYv&index=44)


Disclaimer
==========
While I have used these routines successfully in my own missions, some may still be in an alpha state.  Use at your own risk.
   



