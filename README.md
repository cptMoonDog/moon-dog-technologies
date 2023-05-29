Moon Dog Technologies Software Repository
===========================
The Moon Dog Technologies Consortium was the dream of one man, and now that of several dozen citizens of Kerbin.

Herein you will find a full featured suite of navigational software built in the [kOS](https://KSP-KOS.github.io/KOS) framework, and features and utilities to accompany the instructional videos on [YouTube](https://www.youtube.com/channel/UCXrQZx4C1a3GPn7DXkyWhfw).

For more information, be sure to check out the [wiki](https://github.com/cptMoonDog/moon-dog-technologies/wiki).

Most Recent Changes
==================
Automated missions are increasingly easy to setup.  The initial launch system is stable, and understands how to hand-off control to payload and mission firmware.
`payload.ks` boot file now can load `mission` firmware and transition to it.  `lv.ks` can transition to `payload.ks` on the same core, when using the `launch.conf/current.launch` parameters file.

Automated constellation deployments tested with the `lv/Chihuahua.ks` launch vehicle and the craft file you can find here: 
[Model craft](https://kerbalx.com/yehoodig/Mayflower-Constellation-LC)
To try it yourself, use the `lv.ks` bootfile on the upperstage, and ensure that the core:tag is empty.  Add your parameters for the LV and payload to `launch.conf/current.launch`, make sure that all the satellites have `payload.ks` as boot file, and `[Sat Name]:[Mission], [param1], ..., [param n] in the core:tag.  (It should be ready out of the box.  Just click launch, and it should automatically deploy a constellation of 4 satellites.).


Quickstart
==========

Set your kOS core boot file to `ish.ks` to start in interactive mode.  Once at the prompt, type `setup-launch` or `display commands` to get an idea how it works.


Libraries
---------
The libraries are Scope-Lexicon-Delegate libraries inspired by [gisikw's KNU system.](https://www.youtube.com/watch?v=cqtMpk2GaIY&list=PLb6UbFXBdbCrvdXVgY_3jp5swtvW24fYv&index=44)


Disclaimer
==========
While these routines have been used successfully on occasion, they come with ABSOLUTELY NO WARRANTEE.  Use at your own risk.
