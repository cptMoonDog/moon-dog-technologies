MDTech Programs
===============

*Disclaimer:* Much of what you find here has been used successfully in my own missions, but many are still works in progress and may be in an Alpha state.  Use at your own risk.

Every one of these programs by right should have it's own dedicated project, for everything that I have learned in making them.  In other words, please forgive the mess.  You will find programs that are working quite well, and others that are still in progress, and comments may be inconsistent or outdated.  

What is a Program?
=================
A program, is a kOS script file that makes a set of sub-routines available to the system.  
Once they are made available, they can be added to the `MISSION_PLAN` by 
calling `kernel_ctl["add"](<program name>, <parameter list>).`

A well behaved program file will look something like this:

    
#### Standard boiler plate 

    @lazyglobal off.
    local programName is "docking". //<------- put the name of the script here
    if not (defined kernel_ctl) runpath("0:/lib/core/kernel.ks"). 

#### Open Execution Scope Delegate 

    kernel_ctl["availablePrograms"]:add(programName, {
      
#### Ensure Necessary libraries are loaded

    //======== Imports needed by the program =====
       if not (defined maneuver_ctl) kernel_ctl["import-lib"]("lib/maneuver_ctl").
       if not (defined phys_lib) kernel_ctl["import-lib"]("lib/physics").
       
#### Parameter and Local Variables

    //======== Parameters used by the program ====
       declare parameter argv.
       local tgtPort is "".
       local localPort is "".

       if argv:split(" "):length > 1 {
          if argv:split(char(34)):length > 1 { //char(34) is quotation mark
             set tgtPort to argv:split(char(34))[1]. // Quoted first parameter
             set tgtPort to tgtPort + ":"+argv:split(":")[1]:split(" ")[0].
          } else set tgtPort to argv:split(" ")[0].
          set localPort to argv:split(" ")[argv:split(" "):length-1].
          set kernel_ctl["output"] to "target: "+ tgtPort.
       } else {
          set kernel_ctl["output"] to
             "Docks with the given target port"
             +char(10)+"Usage: add docking [TARGET]:[PORT] [LOCAL PORT (Optional)]".
          return.
       }
    
    //======== Local Variables =====
       declare function getControlInputForAxis {
                   .
                   .
                   .
       }
       declare function steeringVector {
                   .
                   .
                   .
       }

       local port is ship:dockingports[0].
       local standOffFore is 100. // Don't approach closer than 100m until aligned.
                   .
                   .
                   .
       local safeDistance is 25.
       
    //=============== Begin program sequence Definition ===============================
       kernel_ctl["MissionPlanAdd"](programName, {
                   .
                   .
                   .
             if ... {
                return OP_FAIL.
             }
                   .
                   .
                   .
          if ... return OP_FINISHED.
                   .
                   .
                   .
          maneuver_ctl["add_burn"](steerDir, engineName, "ap", dv).
          return OP_FINISHED.
       }).
       kernel_ctl["MissionPlanAdd"](programName, maneuver_ctl["burn_monitor"]).
       kernel_ctl["MissionPlanAdd"](programName, {
          if ... {
                   .
                   .
                   .
             lock throttle to 0.1.
             return OP_CONTINUE.
          } else if ... {
             return OP_CONTINUE.
          }
          return OP_FINISHED.
       }).
    //========== End program sequence ===============================
       
    }). //End of scope delegate


Program Implementation
======================
The key point to note, is that a program opens a scope that is stored in `kernel_ctl["availablePrograms"]`.  Everything a program does from that point on occurs within that scope.
This is important, because it allows the definition of static variables, for use throughout the full course of the program.  

When the scope is activated, the routines defined within it are added to the `MISSION_PLAN`, and will be executed in their turn as the full mission proceeds.

Parameters
----------
Programs should only have *one* parameter, a string.  This is to allow for compatibility with a generalized system.  You can pass as many parameters as you like, but you will have to parse them out of the single string.  You will want to include some error handling logic, and add a help message as show, as it can be shown to the user if they try to use the program wrong.

Local Variables
---------------
Anything static that your program will need can go here.  As you can see, variables and even functions are perfectly happy to hang out in this scope.


Programs Sequence Definition
----------------------------
In the program sequence definition, is where the actual program code is defined.  You can have as many sequential steps in your program as you would like.  The `return` statement controls sequence flow.  `OP_CONTINUE` tells the kernel to run the same routine again, `OP_FINISHED` tells the kernel to advance to the next routine in the `MISSION_PLAN`, `OP_PREVIOUS` (theoretically) tells the kernel to go back to the previous routine in the sequence, and `OP_FAIL` informs the kernel that there has been an error.  

Abort modes are a work in progress.  The likely outcome of returning `OP_FAIL` is a system shutdown.


