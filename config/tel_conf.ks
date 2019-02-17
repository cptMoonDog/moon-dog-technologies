//Categories
telemetry_ctl["items"]:add("misc", lexicon()).
telemetry_ctl["items"]:add("eta", lexicon()).

//Items
telemetry_ctl["items"]["misc"]:add("Alt", {return ship:altitude.}).
telemetry_ctl["items"]["eta"]:add("Apo", {return eta:apoapsis.}).

// A layout is a list of lists.  top, left, width, Height is defined by number of items, title and items. 
   telemetry_ctl["layouts"]:add("default", list(
      list(0, 0, 10, "flight", "eta:Apo", "misc:Alt", "eta:Burn"),
      list(5, 0, 10, "ETAs:", "eta:Apo"))).