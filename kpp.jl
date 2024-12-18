include("lib.jl")
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

  the = (;Dict(Symbol(k) => coerce(v) 
  for (k,v) in eachmatch(r" -(\S+)[^=]+= *(\S+)",about))...) 

#------------------------------------------------------------------------------
@kwdef mutable struct Data rows=[]; cols=nothing end
@kwdef mutable struct Cols all=[]; x=[]; y=[]; names=[]; klass=nothing end
@kwdef mutable struct Sym  pos=0; txt=""; n=0; all=[]; mode=nothing; most=0 end
@kwdef mutable struct Num  
  pos=0; txt=""; n=0; goal=1; mu=0; sd=0; md=20; lo=Big; hi=-Big end

NUM(s::Str, pos::Int) = Num(pos=pos, txt=s, goal= s[end]=="-" ? 0 : 1)
COL(s::Str, pos::Int) = (occursin(r"^[A-Z]", s) ? NUM : Sym)(pos=pos,txt=s)

COLS(v::Vector) = begin
  i = Cols(names=v)
  for (n,(s,col)) in enumerate(zip(v, names))
    col = COL(s,n)
    push!(i.all, col)
    if s[end] != "X" 
      if s[end] == "!" i.klass=col end
      (occursin(s[end],"!+-") ? i.y : i.x)[n] = col end end  
  i end

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

#-------------------------------------------------------------------------------
