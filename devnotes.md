Rocket design
=========

Question: Where do the cores go, and what are they responsible for?

Right now, the launch code lives on the upper stage.  The booster doesn’t get its own core, so it falls away dumb, usually.  

The upper stage continues the launch sequence, but it is sometimes useful for later parts of the mission.

Option1: Break up the launch code.  Non-viable, throttle and steering control needs to be continuous.  

Decision: Booster simply has a separate control unit to handle landing in addition to upper stage control unit.  Need to add capability of staging before fuel runs out, though.  Possibly hijack staging on the booster core.

Option 2: Upper stage dumps launch code after orbit established, and swaps out for a mission.  Problem is, how to pass mission information to the core?  The core:tag is already dedicated to launch parameters.  The question becomes, either continue to use core:tag, or offload parameters to say a dedicated file.  The problem with that, is if you have multiple core with the same boot script, like a comsat, then you can’t address them individually.  Could of course have a parameters file for launch, and use core:tag for mission cores.

Decision: Simple.  Have two cores on the upper stage.  One running lv.ks, and the other running payload.ks.  The handoff happens, no need to build an entire separate control unit.  

Transfer orbits
==========

Need to make orbit design for transfer orbits easier.  Make pe change part of the routine

Programs
========

Make available programs lexicon part of kernel_ctl