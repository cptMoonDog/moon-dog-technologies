// For launch vehicles, the display function is setup in launch/launch_ctl.ks.  Layouts and telemetry items are in config/tel_conf.ks
@LAZYGLOBAL OFF.
global telemetry_ctl is lexicon().

{
   clearscreen.
   telemetry_ctl:add("items", lexicon()).
   telemetry_ctl:add("layouts", lexicon()).
   telemetry_ctl:add("active layout", "default").
   runpath("0:/config/tel_conf.ks").

///Public functions
   declare function show {
      for m in telemetry_ctl["layouts"][telemetry_ctl["active layout"]] {
         local iter is m:iterator.
         iter:next.//0 iterator starts at -1
         //Layout begins with 3 values: top, left, width.  Height is defined by the number of items.
         local top is iter:value.
         iter:next.//1
         local left is iter:value.
         iter:next.
         local width is iter:value.
         iter:next.
         local title is iter:value.
         print title at(left, top).
         until not iter:next {
            local cat is iter:value:split(":")[0].
            local label is iter:value:split(":")[1].
            if not title:toupper:contains(cat:toupper)
               set label to iter:value.
            
            if telemetry_ctl["items"][cat]:haskey(iter:value:split(":")[1]) {
               print constructItem(width-2, label,
                  //                     category                  item name
                  telemetry_ctl["items"][cat][iter:value:split(":")[1]]()) at(left+2, top+iter:index-3).
            }
         }
      }
   }
   telemetry_ctl:add("display", show@).

///Private functions
   declare function constructItem {
      parameter width.
      parameter label.
      parameter datum.

      local line is label+":".
      if datum:istype("String")
         set line to line + datum.
      else
         set line to line + round(datum, 3):tostring:padleft(max(1, width-line:length)).
      return line.
   }
}
