// KNU library management system.
// Thanks to CheersKevin (youtube), gisikw (github)
// Allows for namespace seperation, by maintaining a lexicon of libraries.
// A library often itself being a lexicon of function delegates, although I do not think 
// this is a checked for.  In other words, a library could export itself as any kind of collection,
// but it is up to the end user to know how that library functions.
// 
// Additions made by James McConnel, default search paths, basic error checking, and
// changes to the function names.
// I like the cpp sounding names, plus longer weirder names will likely reduce name collision possibility even more.
{
   local s is stack().
   local d is lex().

   local search_paths is list("", "lib/").

  global import_ns_from is {
     parameter path.
     parameter name.

     if not d:haskey(name) { // If namespace already exists in memory just return it.
        s:push(name).
        if exists("0:/"+path+"/"+name) {
           copypath("0:/"+path+"/"+name,"1:/").
           runpath("1:/"+name).
        }
     }
     return d[name].
  }. 

  global import_namespace is {
      parameter n.

      if not d:haskey(n) { // If namespace already exists in memory just return it.
         s:push(n).
         for p in search_paths {// Figure out where it is.
            print p+n.
            if exists("0:/"+p+n) {
               print "EXISTS!".
               copypath("0:/"+p+n,"1:/").
               break.
            }
         }
         runpath("1:/"+n).
      }
      return d[n].
   }.
   global export_namespace is{
      parameter v.
      set d[s:pop()] to v.
   }.
}
