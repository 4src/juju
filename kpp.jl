include("lib.jl")
about="
kseed.lua : multi-objective optimization via kmeans++ initialization.
(c) 2024 Tim Menzies <timm@ieee.org>, MIT license.

USAGE:
  lua kseed.lua [OPTIONS]  

OPTIONS:
  -d data   csv file of data        = data/auto93.csv 
  -p p      coefficient of distance = 2
  -r rseed  random number seed      = 1234567891
  -s some   #samples searched for each new centroid = 32"

the = (;Dict(Symbol(k) => coerce(v) 
        for (k,v) in eachmatch(r" -. (\S+)[^=]+= *(\S+)",about))...) 

#------------------------------------------------------------------------------
@kwdef mutable struct Data rows=[]; cols=nothing end
@kwdef mutable struct Cols all=[]; x=[]; y=[]; names=[]; klass=nothing end
@kwdef mutable struct Sym txt=""; pos=0; n=0; has=[]; mode=nothing; most=0 end
@kwdef mutable struct Num  
  txt=""; pos=0; n=0; goal=1; mu=0; sd=0; m2=0; lo=Big; hi=-Big end

Col = Union{Sym,Num}

#-------------------------------------------------------------------------------
adds(i::Col,  v::Vector) = [add(i,row) for row in v] 
adds(i::Data, file::Str) = csv(open(file), (row) -> add(i,row)) 

function adds(v::Vector; i=nothing) 
  i = if isnothing(i) (first(v) isa Number ? Num : Sym)() else i end
  [add(i,x) for x in v]
  i end

#-------------------------------------------------------------------------------
function COLS(i::Cols, names::Vector) 
  i.names = names
  for (n,s) in enumerate(names)
    col = if isuppercase(first(s)) 
            Num(txt=s, pos=n, goal= last(s)=='-' ? 0 : 1)
          else 
            Sym(txt=s, pos=n) end
    push!(i.all, col)
    if last(s) == 'X' continue end
    if last(s) == '!' i.klass=col end
    push!(occursin(last(s), "!+-") ? i.y : i.x,  col) end 
  i end

#-------------------------------------------------------------------------------
add(i::Cols, row::Vector)::Vector = [add(j, row[j.pos]) for j in i.all] 
add(i::Data, row::Vector) =
  isnothing(i.cols) ? i.cols=COLS(Cols(),row) : push!(i.rows, add(i.cols,row)) 

function add(i::Col, x::Atom)::Atom
  if x != "?" 
    i.n  += 1
    _add(i,x) end
  x end
 
function _add(i::Num, x::Atom)
  d     = x - i.mu
  i.mu += d / i.n        # mu' = mu + (x-mu)/n
  i.m2 += d * (x - i.mu) # sd' = sd + (x-mu)(x-mu')
  i.sd  = i.n < 2 ? 0 : (i.m2/(i.n - 1))^0.5
  i.lo  = min(i.lo, x)
  i.hi  = max(i.hi, x) end

function _add(i::Sym, x::Atom) 
  n = i.has[x] = 1 + get(i.has, x, 0)
  if n > i.most 
    i.most,i.mode = n,x end end 
