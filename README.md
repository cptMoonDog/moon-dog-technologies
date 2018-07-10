KOS Mission Running System
===========================
A comprehensive system for rapid development and deployment of automated space missions in Kerbal Space Program, using Kerbal Operating System (KOS).
Primarily focused on reducing non-reusable code, while maintaining significant flexibility.

Features
========
 - Rapid Launcher Family development and optimization
 - Efficient, fully customizable Gravity Turns
 - Modular, pluggable mission development
 
How It Works
------------
There are extensive comments in the scripts, please see them for specific documentation (What's that, you don't read source files? No time like the present to start!) however here is a brief introduction:
 - `programs` are scripts that achieve a well defined objective; e.g. change-pe, warp-to-soi, etc. They are intended for use within a larger `mission`.  However, they may be invoked individually from the command line with the following syntax:
   - `runpath("0:/runprogram.ks", [PROGRAM NAME], list([PARAMETER 1], [PARAMETER 2], ... [PARAMETER n]).`
 - `missions` are scripts that run a series of `programs` to achieve a specific goal.  
 - `lv`       contains definition files for Launch Vehicles.  That launcher family you want to make, but can never remember the optimal launch profile?  Never again, one and done!
 - `config`   contains minor settings, like engine performance data and custom throttle functions for the ascent program.
 - `lib`      contains scripts that are more general or less discrete than in `programs`
 - `boot`     contains several scripts that make building generalized Launch Vehicles easier.

Boot Scripts
------------
 - When you build your payload (with KOS module), change the nameTag of the KOS part to the name of the `mission` you want it to run, and use the boot file `payload_boot.ks` to automatically run that mission after the `lv` achieves a circular orbit. This will also change the name of the ship to the name of the mission.
 - When you build the Launch Vehicle (with KOS module), change it's nameTag to the name of the `lv` definition you want it to use, and us the boot file `lv_boot.ks`.  The nameTag field also accepts up to 3 parameters: Inclination, RAAN and Orbit Altitude, so you don't have to modify the lifter definition for minor launch differences.
 - One benefit of this, is that the lifter can be developed under one name, the craft file on launch can have another and the mission itself a third!
 - Caution: Don't forget to change the nameTag on the KOS Module!
    
Note: There is no restriction on the normal use of KOS.  You can have this system in your scripts folder with no loss or change in functionality.

Slightly More Detailed
----------------------
 - `lib/core/kernel_ctl.ks` defines a Turing Complete runmode system.
    - What this means: Subroutines are added to the `MISSION_PLAN` list by the user, or other functions in this library, each subroutine is run repeatedly until it tells the system to advance to the next.
    - `MISSION_PLAN` subroutines work best, when programmed without loops or wait statements, because the whole system is running in a loop.
 - `programs` are scripts that add functions (delegates) to the `available_programs` lexicon.  Each of these is an initializer, which when run, adds the function(s) implementing the program to the `MISSION_PLAN` list.

Disclaimer
==========
While I have used these routines successfully in my own missions, some may still be in an alpha state.  Use at your own risk.
   



