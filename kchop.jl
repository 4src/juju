module kseed
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

@kwdef mutable struct Data rows=[]; cols=nothing end
@kwdef mutable struct Cols all=[]; x=[]; y=[]; names=[] end
@kwdef mutable struct Sym  pos=0; txt=""; n=0; all=[]; mode=nothing; most=0 end
@kwdef mutable struct Num  
  pos=0; txt=""; n=0; goal=1; mu=0; sd=0; md=20; lo=Big; hi=-Big end

#-------------------------------------------------------------------------------
adds(i::Data, v::Vector) = [add(i,row) for row in v] 
adds(i::Data, file::Str) = csv(open(file), (row) -> add(i,row)) 

add(i::Cols, row::Vector)::Vector = [add(j, row[j.pos]) for j in i.all] 
add(i::Data, row::Vector) = 
  isnothing(i.cols) ? i.cols = COLS(row) : push!(i.rows, add(i.cols,row)) 

function add(i, x::Atom)::Atom
  if x != "?" 
    i.n  += 1
    _add(i,x) end
  x end
 
function _add(i::Num, x::Atom)
  d     = x - i.mu
  i.mu += d / i.n        # mu' = mu + (x-mu)/n
  i.sd += d * (x - i.mu) # sd' = sd + (x-mu)(x-mu')
  i.lo  = min(i.lo, x)
  i.hi  = max(i.hi, x) end

function _add(i::Sym, x::Atom) 
  tmp = i.has[x] = 1 + get(i.has, x, 0)
  if tmp>i.most 
    i.most,i.mode=tmp,x end end 

#-------------------------------------------------------------------------------
csv(src::IOStream, fun::Fun) = 
  while ! eof(src)
    new = replace(readline(src), r"([ \t\n]|#.*)"=>"")
    if sizeof(new) != 0
      fun(map(coerce,split(new, ","))) end end

oo(x)            = println(o(x)) 

o(i::Atom)       = string(i)  
o(i::Array)      = "[" * join(map(o,i),", ")*"]" 
o(i::NamedTuple) = "(" * join(sort!(
                    [":$f $(o( getfield(i,f)))" for f in keys((i))])," ")*")"
o(i::Any) = "$(typeof(i)){" * join([
            ":$f $(o(getfield(i,f)))" for f in fieldnames(typeof(i))]," ")*"}" 

cli(nt::NamedTuple) = (;cli(Dict(pairs(nt)))...)
cli(d::Dict) = begin
  for (k,v) in d 
    s=String(k) 
    for (argv,flag) in enumerate(ARGS) 
      if flag in ["-"*s[1],  "--"*s]
        d[k]= v==true ? false : (
              v==false ? true : coerce(ARGS[argv+1])) end end end
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
oo(the) 

end