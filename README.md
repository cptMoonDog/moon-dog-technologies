Moon Dog Technologies Software Repository
===========================
The Moon Dog Technologies Consortium was the dream of one man, and now that of several dozen citizens of Kerbin.

Herein you will find a full featured suite of navigational software built in the [kOS](https://KSP-KOS.github.io/KOS) framework, and features and utilities to accompany the instructional videos on [YouTube](https://www.youtube.com/channel/UCXrQZx4C1a3GPn7DXkyWhfw).

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
