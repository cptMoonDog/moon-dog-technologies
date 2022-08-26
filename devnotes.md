Rocket design
=========
Rendezvous
==========
Starting to work better, but can be "too good", need to slow down sooner and slowly move in on a final approach.

Hibernation
===========
Sometimes a mission plan includes a long trip.  How do we handle rebuilding the same state after player absence?  Well, how do we build mission plans in general?  Up till now, they were either built through ISH, or defined in bespoke files during the previous mission paradigm.

Decsion: Will need two systems.  For ISH, it’s fine to build an abbreviated plan file, because we only would be using programs.  

For automatic mode, plan has to be a ks file, to allow for custom runmodes.  Good thing is, we don’t have to build it programmatically, user would have to supply.

Launch can’t be hibernatable until after apoapsis established.


General Todo
=========

Need to add better error reporting to OP fail codes

Work on docking continues.  Quoted parameters works well.  Docking is extremely difficult without a well designed RCS system.  Need to detect wobble in ship so that we can fail without stranding the crew.


Not sure I ever got the change-LAN working reliably.

Deorbit: Consider when you drop everything except the capsule, there is no core left to finish the final reentry sequence.  How do we handle that?

Landing, ugh.  May someday I will get this.

Booster landings.  Need to learn how to navigate.

