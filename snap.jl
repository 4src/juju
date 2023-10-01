using MutableNamedTuples
help="
tiny.jl: a fast way to find good options
(c) Tim Menzies <timm@ieee.org>, BSD-2 license

OPTIONS:
  -b --bins   initial number of bins   = 16
  -C --Cohen  too small                = .35
  -f --file   csv data file            = ../data/auto93.csv
  -F --Far    how far to look          = .95
  -h --help   show help                = False
  -H --Half   where to find for far    = 256
  -m --min    min size                 = .5
  -p --p      distance coefficient     = 2
  -r --reuse  do npt reuse parent node = true
  -s --seed   random number seed       = 937162211"

function coerce(x)
  for thing in [Int32,Float64,Bool] if (y=tryparse(thing,x)) != nothing return y end end 
  x end

the=(;Dict(Symbol(k) => coerce(v) for (k,v) in eachmatch(r"\n.*--(\S+)[^=]+= *(\S+)",help))...) 
#---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ----------  
NAMES = MutableNamedTuple

function COL(i::String) occursin(r"^[A-Z]", i) ? [] : Dict() end

inc!(i,x)          = if x != "?" inc1!(i,x) end  
inc1!(i::Vector,x) = push!(i,x)  
inc1!(i::Dict,  x) = (i[s] = get(i,x,0) + 1) 

mid(i::Vector) = per(i, .5)
mid(i::Dict)   = findmax(i)[2]

div(i::Vector) = (per(i, .9) - per(i, .1))/2.46
div(i::Dict)   = entropy(i) 

norm(i::Vector, x) = x=="?" ? x : (x - i[1]) / (i[end] - i[1] + 1/BIG)
norm(i::Dict,   x) = x

function dist(i::Dict,  x,y)  (x=="?" && y=="?") ? 1 : (x==y ? 1 : 0) end
function dist(i::Vector,x,y) 
  if (:x=="?" && y=="?") 1 else
    x,y = norm(i,x), norm(i,y)
    if x=="?" x = (y < .5 ? 1 : 0) end
    if y=="?" y = (x < .5 ? 1 : 0) end 
    abs(x - y) end end

function DATA(src) 
  data = NAMES(rows=[], cols=nothing)
  src isa String ? csv(src, row -> data!(row)) : [data!(row) for row in src]  
  [sort(col) for col in data.cols.all if col isa Vector]
  data end

function data!(data, row)
  if data.cols == nothing  data.cols=COLS(row) else
    [inc!(col,x) for (col,x) in zip(data.cols.all,row)]
    push!(row, data.rows) end end

function COLS(v::Vector{String})
  klass, x, y, all = nothing, Dict(), Dict(), [COL(s) for s in v]
  for (n,(s,col)) in enumerate(zip(v,all))
    if s[end] != "X" 
      if s[end]=="!" klass=col end
      (occursin(s[end],"!+-") ? y : x)[n] = col end end
  NAMES(all=all, x=x, y=y, names=v) end
  
clone(data, src=[]) = DATA( vcat([data.cols.name],src) )

#---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- -----------
BIG = 1E30

int(n::Number)         = floor(Int,n)
any(v::Vector)         = v[ rani(1,length(v))  ]
many(v::Vector,n::Int) = [any(v)  for _ in 1:n]

per(v::Vector,p=.5) = v[ max(1, int(p*length(v)))]

function entropy(d::Dict)
  N = sum((n for (_,n) in d))
  -sum(n/N*log2(n/N) for (_,n) in d if n>0) end

rseed=the.seed
function rani(nlo, nhi)  floor(Int, .5 + ranf(nlo,nhi)) end
function ranf(nlo=0, nhi=1) 
  global rseed = (16807 * rseed) % 214748347 
  nlo + (nhi - nlo) * rseed / 214748347 end

function csv(sfile, fun)
  src = open(sfile)
  while ! eof(src)
    new = replace(readline(src), r"([ \t\n]|#.*)"=>"")
    if sizeof(new) != 0
      fun(map(coerce,split(new,","))) end end end

function cli(d)
  tmp = Dict()
  for (k,v) in pairs(d) 
    s=String(k)
    tmp[k] = v
    for (i,flag) in enumerate(ARGS)
      if (flag=="-"*s[1] || flag=="--"*s)
        tmp[k] = s==true ? false : (s==false ? true : coerce(ARGS[i+1]))  end end end
  NAMES(;tmp...) end

#-----------------------------------------------
eg_settings() = println(the)
eg_csv() = csv(the.file, (r) -> println(r))

egs = Dict(
  "settings" => eg_settings, 
  "csv"      => eg_csv
)
#-----------------------------------------------
if abspath(PROGRAM_FILE) == @__FILE__
  the = cli(the)
  for arg in ARGS
    for (s,fun) in egs 
      if arg == split(s)[1] fun() end end end end 