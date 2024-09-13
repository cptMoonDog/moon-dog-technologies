# Moon Dog Technologies is in need of faculty and research and development staff.  

## We need help in the following areas:

### Instructors: 
#### Job Requirements: 
Make videos and instructional materials about rocket science!  There are new people coming to the game all the time, and any help you can give them will get you an honorary degree from the academy.  If you want to use mdTech to do so, we would love to hear how you found it useful.  We aim to make the pre-eminent KOS automation suite available.

#### Compensation: 
If you post your lesson or tutorial here, you will get a hearty pat on the back!

#### Necessary Experience: 
Whatever you have.  Teach what you know, and you will discover even more.

### Moon Dog Technologies Associate Developer:
#### Job Requirements: 
We need help in all areas to improve the Moon Dog Technologies software suite.  Currently, we have a drop-in shell program to simplify high-level scripting and mission development, along with many pre-built routines.  We need help adding new routines, debugging, and adding documentation.  To get a sample of capabilities, check out the videos.

#### Compensation: 
Our gratitude, high praise and credit, and the good feeling that you beat MechJeb in a toy language. :D
Necessary Experience: Any contributions are welcome.  We aim to educate, enlighten, and elevate.  Regardless of how little or much experience you have, if you have a new drop-in program, or an improvement, we appreciate any contributions, or discussions.

Moon Dog Technologies Software Repository
===========================
The Moon Dog Technologies Consortium was the dream of several dozen citizens of Kerbin.

Herein you will find a full featured suite of navigational software built in the [kOS](https://KSP-KOS.github.io/KOS) framework.

Major Features
==============
  - Interactive Shell 
  - Highly flexible, and extensible launch system.
  - High-level Mission Scripting
    - Allows for adding prebuilt programs to custom sequences.
    - Rapid mission automation
  - Assignable firmware

Quickstart
==========

Set your kOS core boot file to `ish.ks` to start in interactive mode.  Once at the prompt, type `help`.

Non-interactive mode has multiple entry points.  If you know your way around kOS, start in the `boot` folder.
  - `lv.ks`
  - `payload.ks`

You can ignore the others, for now.
Basically...`lv.ks` checks the `core:tag` for parameters.  Either, give it: `[LAUNCH VEHICLE NAME], [INCLINATION], [LAN], [ORBIT ALTITUDE]`, or specify a `.launch` file.

Other Resources
===============
[Satellite Constellation Designer](https://docs.google.com/spreadsheets/d/1LfuaOlbYhqdkZ5u4zmiUqkcERuGFl3m6GwSdb_gjIsI/edit?usp=sharing)


Most Recent Changes
==================
22SEP2023
 - Is there anyone out there?  If you have been using any enjoying this system, it would be great to hear some feed back.  Just email the captian via gmail.
 - On the off-chance that there are any of you out there, I'm trying to be more polite, by respecting your expectations, but I may still break things.
 - I this release, I've tried to make things easier by changing the "add" ISH command with "Q", as in Queue this program.  It is by far, the most common command I use, so this should make life easier.
 - Added a "countdown" program so you can add a simple countdown in the MISSION_PLAN.
 - Also tuned the docking program.
 
06JUL2023
 - Streamlined `circularize` program and added more helps.

05JUL2023
 - Empty core:tag now fails as is intuitive.  
 - Specifying a "<name>.launch" is required to source launch parameters from the launch.conf directory.

21JUN2023
 - Added online help to th interactive shell
 - Uploaded a video of it to [YouTube](https://youtu.be/8KXW-6Rhv8E)
 - Fixed a bug in `setup-launch`

08JUN2023
 - Fixed a bunch of bugs and made some quality of life improvements in the Interactive SHell system.
 - Changed some of the commands to be more Spacey.
 - Status and Countdown lines should be displaying properly now.
 
Automated missions are increasingly easy to setup.  The initial launch system is stable, and understands how to hand-off control to payload and mission firmware.
`payload.ks` boot file now can load `mission` firmware and transition to it.  `lv.ks` can transition to `payload.ks` on the same core, when using the `launch.conf/current.launch` parameters file.

Automated constellation deployments tested with the `lv/Chihuahua.ks` launch vehicle and the craft file you can find here: 
[Model craft](https://kerbalx.com/yehoodig/Mayflower-Constellation-LC)
To try it yourself, use the `lv.ks` bootfile on the upperstage, and ensure that the core:tag is empty.  Add your parameters for the LV and payload to `launch.conf/current.launch`, make sure that all the satellites have `payload.ks` as boot file, and `[Sat Name]:[Mission], [param1], ..., [param n] in the core:tag.  (It should be ready out of the box.  Just click launch, and it should automatically deploy a constellation of 4 satellites.).



Libraries
---------
The libraries are Scope-Lexicon-Delegate libraries inspired by [gisikw's KNU system.](https://www.youtube.com/watch?v=cqtMpk2GaIY&list=PLb6UbFXBdbCrvdXVgY_3jp5swtvW24fYv&index=44)


Disclaimer
==========
While these routines have been used successfully on occasion, they come with ABSOLUTELY NO WARRANTEE.  Use at your own risk.
