@lazyglobal off.
declare parameter name.
declare parameter p is list().

local allowAlpha is false.
local allowBeta is false.

if exists("0:/programs/std/"+name+".ks") 
   runpath("0:/programs/std/"+name+".ks").
if allowAlpha AND exists("0:/programs/alpha/"+name+".ks") 
   runpath("0:/programs/alpha/"+name+".ks").
if allowBeta AND exists("0:/programs/beta/"+name+".ks") 
   runpath("0:/programs/beta/"+name+".ks").
if available_programs:haskey(name) {
   if p:length = 0 available_programs[name]().
   if p:length = 1 available_programs[name](p[0]).
   if p:length = 2 available_programs[name](p[0], p[1]).
   if p:length = 3 available_programs[name](p[0], p[1], p[2]).
   if p:length = 4 available_programs[name](p[0], p[1], p[2], p[3]).
   if p:length = 5 available_programs[name](p[0], p[1], p[2], p[3], p[4]).
   if p:length = 6 available_programs[name](p[0], p[1], p[2], p[3], p[4], p[5]).
   if p:length = 7 available_programs[name](p[0], p[1], p[2], p[3], p[4], p[5], p[6]).
   if p:length = 8 available_programs[name](p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7]).
   if p:length = 9 available_programs[name](p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8]).
   kernel_ctl["start"]().
   shutdown.
} else print "Program named: "+name+" Does not exist".

   
