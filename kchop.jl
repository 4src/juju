me() = include("kchop.jl")
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

function as(s)
  for t in [Int32,Float64,Bool] 
    if ((x=tryparse(t,s)) != nothing) return x end end 
  s end

it=(;Dict(Symbol(k) => as(v) for (k,v) in eachmatch(r" -(\S+)[^=]+= *(\S+)",this))...) 

#------------------------------------------------------------------------------
Big,Str,Fun = 1E32,String,Function

@kwdef mutable struct Num   
  at=0; txt=""; utopia=1; n=0; mu=0; sd=0; md=20; lo= Big; hi= -Big end

@kwdef mutable struct Sym   
  at=0; txt=""; n=0; all=[]; mode=nothing; most=0 end
   
NUM(s::Str) = Num(utopia = (s[end] == '-' ? 0 : 1))  

rows(v::Vector, fun::Fun) = [fun(x) for x in v] 
rows(file::Str, fun::Fun) = reads(file,fun)

function reads(file::Str, fun::Fun)
  src = open(file)
  while ! eof(src)
    new = replace(readline(src), r"([ \t\n]|#.*)"=>"")
    if sizeof(new) != 0
      fun(map(what,split(new,","))) end end end

oo(x,pre="") = begin println(o(x,pre)); x end

function o(obj, pre="")
  s= "$pre $(typeof(obj)) {"
  [ s *= ":$f $(getfield(obj, f)) " for f in fieldnames(typeof(obj))]
  s*"}" end 

o(obj::Vector,pre="") =  "$pre[" * join(obj,", ") * "]"

oo([1,2 ,3])
#-------------------------------------------------------------------------------
print(o(Num(txt="aadas-"))) 