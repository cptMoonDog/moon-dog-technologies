// Telemetry system is started by: 
         //runpath("0:/lib/core/telemetry.ks").
         //INTERRUPTS:add(telemetry_ctl["display"]).
//Categories
telemetry_ctl["items"]:add("misc", lexicon()).
telemetry_ctl["items"]:add("eta", lexicon()).

//Items
telemetry_ctl["items"]["misc"]:add("Alt", {return ship:altitude.}).
telemetry_ctl["items"]["misc"]:add("Ap", {return ship:apoapsis.}).
telemetry_ctl["items"]["eta"]:add("Ap", {return eta:apoapsis.}).
telemetry_ctl["items"]["eta"]:add("Pe", {return eta:periapsis.}).

// A layout is a list of lists.  Layout is defined by: top, left, width, height is defined by number of items plus title. 
   telemetry_ctl["layouts"]:add("default", list(
      list(0, 0, 10, "flight:", "misc:Ap", "eta:Burn"),
      list(5, 0, 10, "ETAs:", "eta:Ap"))).