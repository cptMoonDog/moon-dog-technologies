KOS Mission Planning System
===========================

How it works, short version:
 - `lib/core/kernel_ctl.ks` defines a runmode system.
    - This is neat, because it will run functions added to the `MISSION_PLAN` repeatedly until the system is told to advance to the next.
    - Functions are expected to return one of the following:
       - `OP_CONTINUE` if they wish to be run again.
       - `OP_FINISHED` if they believe it is safe to advance to the next objective in the `MISSION_PLAN`.
       - `OP_PREVIOUS` to go back to the previous objective.
       - `OP_FAIL` if a catastrophic error has occured and the MISSION_PLAN cannot continue, i.e. abort and hope the pilot can save himself.
    
    - There is also an `INTERRUPT` list for functions you wish to be executed in parallel.
    - This enables things like the following:

```kerboscript
    runpath("lib/core/kernel_ctl.ks").
    MISSION_PLAN:add(launch_to_orbit@).
    MISSION_PLAN:add(goto_Mun@).
    MISSION_PLAN:add(return@).
    MISSION_PLAN:add(re-entry@).

    kernel_ctl["start"]().
```


Other Things
------------

This library also contains systems to make a few things easier (...or at least reduce non-reusable code).
   - `lv` Contains custom launch profiles for boosters, that way you don't have to create a new profile for a different mission that is using the same booster.
   - `missions` Is where the boot script looks for the mission definition to load.  The script should have the same name as your mission.
   - `objectives` Are custom functions for accomplishing various tasks.  They can be loaded using the `lib/load_objectives.ks` system if so desired.
   - `engine-conf.ks` Contains performance information for engine configurations, that you want to make available to the `lib/maneuver_ctl.ks` system.
   - `lib` Contains routines that are likely to be reused frequently.
      - `lib/launch` works with booster definitions in `lv`.  It is self-contained, so you shouldn't notice it much.
      - `lib/maneuver_ctl.ks` runs maneuvers.
      - `lib/transfer_ctl.ks` makes the calculations for Hohmann transfers.


While I have used these routines successfully in my own missions, some may still be in an alpha state.  Use at your own risk.
   



