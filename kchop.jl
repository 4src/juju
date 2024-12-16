make() = include("kchop.jl")
this="
kseed.lua : multi-objective optimization via kmeans++ initialization.
(c) 2024 Tim Menzies <timm@ieee.org>, MIT license.

USAGE:
  lua kseed.lua [OPTIONS]  

OPTIONS:
  -d file  csv file of data        = ../../moot/optimize/misc/auto93.csv 
  -p int   coefficient of distance = 2
  -r int   random number seed      = 1234567891
  -s int   #samples searched for each new centroid = 32"

what(s) = begin
  for t in [Int32,Float64,Bool] 
    if ((x=tryparse(t,s)) != nothing) return x end end 
  s end

it=(;Dict(Symbol(k)=>what(v) 
     for (k,v) in eachmatch(r" -(\S+)[^=]+= *(\S+)",this))...) 

#------------------------------------------------------------------------------
Big=1E32

@kwdef mutable struct Num   
  at=0; txt=""; n=0; mu=0; sd=0; md=20; lo=Big; hi= -Big; utopia = 1 end
   
function NUM(s::String) 
  Num(utopia = (s[end] == '-' ? 0 : 1)) end

function rows(v::Vector, fun::Function) 
  [fun(x) for x in v] end

function rows(file::String, fun::Function) 
  src = open(file)
  while ! eof(src)
    new = replace(readline(src), r"([ \t\n]|#.*)"=>"")
    if sizeof(new) != 0
      fun(map(what,split(new,","))) end end end