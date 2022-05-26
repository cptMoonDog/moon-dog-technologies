Rocket design
=========

Question: Where do the cores go, and what are they responsible for?

Right now, the launch code lives on the upper stage.  The booster doesn’t get its own core, so it falls away dumb, usually.  

The upper stage continues the launch sequence, but it is sometimes useful for later parts of the mission.

Option1: Break up the launch code.  Non-viable, throttle and steering control needs to be continuous.  

Decision: Booster simply has a separate control unit to handle landing in addition to upper stage control unit.  Need to add capability of staging before fuel runs out, though.  Possibly hijack staging on the booster core.

Option 2: Upper stage dumps launch code after orbit established, and swaps out for a mission.  Problem is, how to pass mission information to the core?  The core:tag is already dedicated to launch parameters.  The question becomes, either continue to use core:tag, or offload parameters to say a dedicated file.  The problem with that, is if you have multiple core with the same boot script, like a comsat, then you can’t address them individually.  Could of course have a parameters file for launch, and use core:tag for mission cores.  Parameters file would of course require a whole different parsing code…not necessarily.

Decision: Simple.  Have two cores on the upper stage.  One running lv.ks, and the other running payload.ks.  The handoff happens, no need to build an entire separate control unit.  

Transfer orbits
==========

Need to make orbit design for transfer orbits easier.  Make pe change part of the routine.  In other words add calculation to relate pe and orbit period.

Programs
========

Make available programs lexicon part of kernel_ctl

Hibernation
===========
Sometimes a mission plan includes a long trip.  How do we handle rebuilding the same state after player absence?  Well, how do we build mission plans in general?  Up till now, they were either built through ISH, or defined in bespoke files during the previous mission paradigm.

How about a mission sequence file, with each line the same as the equivalent ISH command.  But how do I identify which item is the start point on reboot? In hibernatable programs, log name of program at op-continue.

Decision: Make a file called plan.ks that is modified as needed.  If a ship uses the run-plan mission, then copy the plan to the core, and parse the values into the MISSION_PLAN.  Make sure that it is valid kerboscript, so that custom delegates can be defined.

General Todo
=========
