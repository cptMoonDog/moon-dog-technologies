What is this?
============
Launch files are a new paradigm I'm trying.  Long story short, instead of specifying the launch parameters in the core tag, you can can just put them in a dot launch file.  The `lv.ks` bootfile will take parameters from `0:/launch.conf/current.launch` if the core tag is empty.  Just to be explicit, configuration search hierarchy is the core tag first, and then `0:/launch.conf/current.launch`.

Expected format
==============
A `.launch` file is parsed by the `lv.ks` boot file.  It expects either one or two lines of parameters.  It identifies the parameters for the launch vehicle by the `//launch` comment on the preceding line, and similarly the parameters for the payload by the `//payload` comment.
