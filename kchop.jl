about="
kseed.lua : multi-objective optimization via kmeans++ initialization.
(c) 2024 Tim Menzies <timm@ieee.org>, MIT license.

USAGE:
  lua kseed.lua [OPTIONS]  

OPTIONS:
  -d file  csv file of data        = ../../moot/optimize/misc/auto93.csv 
  -p int   coefficient of distance = 2
  -r int   random number seed      = 1234567891
  -s int   #samples searched for each new centroid = 32"

#------------------------------------------------------------------------------
Str,Fun = AbstractString,Function
Atom    = Union{Symbol,Number,Char,Bool,Str}
Big     = 1E32

@kwdef mutable struct Num   
  col=0; txt=""; utopia=1; n=0; mu=0; sd=0; md=20; lo= Big; hi= -Big end

@kwdef mutable struct Sym   
  col=0; txt=""; n=0; all=[]; mode=nothing; most=0 end

@kwdef mutable struct Cols
  all=[]; x=[]; y=[]; w=nothing end

@kwdef mutable struct Data
  rows=[]; cols=nothing end

#-------------------------------------------------------------------------------
adds(i::Data, v::Vector) = [add(i,row) for row in v] 
adds(i::Data, file::Str) = reads(open(file), (row) -> add(i,row)) 

add(i::Cols, row::Vector)::Vector = [add(j, row[j.col]) for j in i.all] 
add(i::Data, row::Vector) = isnothing(i.cols) ? i.cols = COLS(row) : push!(i.rows, add(i.cols,row)) 

function add(i, x::Atom)::Atom
  if x != "?"
    i.n  += 1
    _add(i,x)
  x end

function _add(i::Num, x::Atom)
  d     = value - i.mu
  i.mu += d / i.n
  i.sd += d * (value - i.mu)
  i.lo  = min(i.lo, value)
  i.hi  = max(i.hi, value) end

function _add(i::Sym, x::Atom) 
  tmp = i.has[x] = 1 + get(i.has, x, 0)
  if tmp>i.most 
    i.most,i.mode=tmp,x end end 

#-------------------------------------------------------------------------------
reads(src::IoStream, fun::Fun) =
  while ! eof(src)
    new = replace(readline(src), r"([ \t\n]|#.*)"=>"")
    if sizeof(new) != 0
      fun(map(coerce,split(new, ","))) end end

oo(x)            = println(o(x)) 

o(i::Atom)       = string(i)  
o(i::Array)      = "["*join(map(o,i),", ")*"]" 
o(i::NamedTuple) = "(" * join([":$f $(o( getfield(i,f)))" for f in keys(i)]," ")*")"
o(i::Any)        = "$(typeof(i)){" * join([
                   ":$f $( o( getfield(i,f)))" for f in fieldnames(typeof(i))]," ")*"}" 

cli(nt::NamedTuple) = (;cli(Dict(pairs(nt)))...)
cli(d::Dict) = begin
  for (k,v) in d 
    s=String(k) 
    for (argv,flag) in enumerate(ARGS) 
      if flag in ["-"*s[1],  "--"*s]
        d[k]= v==true ? false : (v==false ? true : coerce(ARGS[argv+1])) end end end
  d end

function coerce(s)
  for t in [Int32,Float64,Bool] 
    x = tryparse(t,s) 
    if ! isnothing(x) return x end end 
  s end
 
the = (;Dict(Symbol(k) => coerce(v) 
       for (k,v) in eachmatch(r" -(\S+)[^=]+= *(\S+)",about))...) 

#-------------------------------------------------------------------------------
oo(Num(txt="fred-",mu=0.333333))
oo([1,2,3,4])
oo(1)
oo(:a)