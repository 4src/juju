import MutableNamedTuples
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
  -r --reuse  do npt reuse parent node = True
  -s --seed   random number seed       = 937162211"

function coerce(x)
  for thing in [Int32,Float64,Bool] 
    if (y=tryparse(thing,x)) != nothing return y end end 
  x end

the=(;Dict(Symbol(k) => coerce(v) 
           for (k,v) in eachmatch(r"\n *-[^-]+--(\S+)[^=]+= *(\S+)",help))...) 
#---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- -----------
function COL(i::String) 
  occursin(r"^[A-Z]", i) ? [] : Dict() end

function COLS(v::Vector{String})
  klass,all,x,y = nothing,[],Dict(),Dict()
  for (n,(s,col)) in enumerate([(s,COL(s)) for s in v])
    if s[end] != "X" print() end end 

inc!(i,x) = if x != "?" inc1!(i,x) end  

inc1!(i::Vector,x)  = push!(i,x)  
mid(  i::Vector)    = per(i, .5)
div(  i::Vector)    = (per(i, .9) - per(i, .1))/2.46
norm( i::Vector, x) = x=="?" ? x : (x - i[1]) / (i[end] - i[1] + 1/BIG)

inc1!(i::Dict, x)   = (i[s] = get(i,x,0) + 1) 
mid(  i::Dict)      = findmax(i)[2]
div(  i::Dict)      = entropy(i) 

function dist(i::Dict, x, y)  
  (x=="?" && y=="?") ? 1 : (x==y ? 1 : 0) end

function dist(i::Vector,x,y) 
  if (x=="?" && y=="?") 1 else
    x,y = norm(i,x), norm(i,y)
    if x=="?" x = (y < .5 ? 1 : 0) end
    if y=="?" y = (x < .5 ? 1 : 0) end 
    abs(x - y) end end

BOX = MutableNamedTuples

aaa(i::Tuple) = 1

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

function csv(sfile,fun)
  src = open(sfile)
  while ! eof(src)
    new = replace(readline(src), r"([ \t\n]|#.*)"=>"")
    if sizeof(new) != 0
      fun(map(coerce,split(new,","))) end end end
