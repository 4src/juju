## Options


```julia
about="
up.jl: smos
(c)2024 Tim Menzies <timm@ieee.org>, BSD-2 license
  
OPTIONS:
  -b --bins   initial number of bins   = 16
  -C --Cohen  too small                = .35
  -f --file   csv data file            =  data/auto93.csv
  -F --Far    how far to look          = .95
  -h --help   show help                = false
  -H --Half   where to find for far    = 256
  -m --min    min size                 = .5
  -p --p      distance coefficient     = 2
  -r --reuse  do npt reuse parent node = true
  -s --seed   random number seed       = 937162211"
```


## Structs
This  code convention:  
   
- `xxx = XXX()` uses the `XXX()`` constructor to create a variable of type `Xxx``.
- e.g.  `sym = SYM()`` creates `sym`, a variable of type `Sym``.
  
`Num`= Numeric columns.


```julia
@kwdef mutable struct Num:w
  at=0; txt=""; n=0; mu=0; m2=0; sd=0; lo=1E-30; hi= -1E-30; heaven=1 end
```


`Sym` = Symbolic columns.


```julia
@kwdef mutable struct Sym
  at=0; txt=""; n=0; has=Dict() end
```


`Cols` = Factory for making and storing `Num`s or `Sym`s.


```julia
@kwdef mutable struct Cols 
  klass=nothing; all=[]; x=Dict(); y=Dict(); names=[] end
```


`Data` = storage for rows and cols.


```julia
@kwdef mutable struct Data rows=[]; cols=nothing end
```


## Columns
Column constructors.


```julia
COL(s=" ",n=0) = (occursin(r"^[A-Z]", s) ? NUM : SYM)(s,n) 
SYM(s=" ",n=0) = Sym(at=n, txt=s) 
NUM(s=" ",n=0) = Num(at=n, txt=s, heaven= s[end]=="-" ? 0 : 1)
```


Column updates.


```julia
function add!(sym::Sym, x) sym.n+=1; sym.has[x]=1+get(sym.has,x,0) end 
function add!(num::Num, x::Number) 
  num.n += 1
  d     = x - num.mu
  num.mu += d / num.n
  num.m2 += d * (x -  num.mu)
  num.sd  =  num.n > 1 ? (num.m2 / (num.n - 1))^.5 : 0
  num.lo = min(x, num.lo)
  num.hi = max(x, num.hi) end
```


Column middle values.


```julia
often(num::Num) = num.mu
often(sym::Sym) = findmax(sym.has)[2]
```


Column deviation from middle.


```julia
spread(num::Num) = num.sd
spread(sym::Sym) = - sum(n/sym.n*log2(n/sym.n) for (_,n) in sym.has if n>0) 
```


Normalization.


```julia
norm(_, x)  = x 
norm(num::Num, x::Number) = (x - num.lo) / (num.hi - num.lo + 1E-30)
```


Columns factor.


```julia
function COLS(v::Vector) 
  cols = Cols(names=v, all= [COL(s,n) for (n,s) in enumerate(v)])
  for (n,(s,col)) in enumerate(zip(v,cols.all))
    if s[end] != "X" 
      if s[end] == "!" klass=col end
      push!(occursin(s[end],"!+-") ? cols.y : cols.x, col) end end  
  cols end
```


## Data


```julia
DATA(x) = adds!(Data(),x)
```




```julia
adds!(x, lst)           = begin [add!(x,y) for y in lst]; x end
adds!(data::Data, file) = begin csv(file, r->add!(data,r)); data end
```




```julia
function add!(data::Data, v::Vector) 
  if data.cols === nothing data.cols=COLS(v) else  
    [add!!(col,x) for (col,x) in zip(data.cols.all, v) if x != "?"]
    push!(data.rows, v) end end
```




```julia
clone(data::Data, src=[]) = adds!(DATA([data.cols.names]),src) 
```




```julia
function d2h(data::Data, v::Vector) 
  d,n  = 0,0
  for (n,col) in data.cols.y 
    d += (col.heaven - norm(col, v[col.at])) ^ 2 
    n += 1 end 
  (d/n) ^ .5 end
```




```julia
int(n::Number) = floor(Int,n)
rnd(x,n=3)     = round(x,sigdigits=n)
```




```julia
function what(s) 
  for t in [Int32,Float64,Bool] 
    if ((x=tryparse(t,s)) !== nothing) return x end end 
  s end
```




```julia
the=(;Dict(Symbol(k)=>what(v) 
      for (k,v) in eachmatch(r"\n.*--(\S+)[^=]+= *(\S+)",about))...)  
```




```julia
shuffle!(v::Vector) = sort(v, by= _ -> rani(1,100000))
```




```julia
rseed=the.seed
function rani(lo::Int, hi::Int) int(.5 + ranf(lo,hi)) end
function ranf(lo=0.0, hi=1.0) 
  global rseed = (16807 * rseed) % 214748347 
  lo + (hi - lo) * rseed / 214748347 end
```




```julia
function csv(sfile, fun::Function) 
  src = open(sfile)
  while ! eof(src)
    new = replace(readline(src), r"([ \t\n]|#.*)"=>"")
    if sizeof(new) != 0
      fun(map(what,split(new,","))) end end end
```




```julia
function cli(nt::NamedTuple) 
  (;cli(Dict(pairs(nt)))...) end
function cli(d::Dict) 
  for (k,v) in d 
    s=String(k) 
    for (argv,flag) in enumerate(ARGS)  
      if flag in ["-"*s[1],  "--"*s] 
        d[k] = v==true  ? false : (
               v==false ? true  : what(ARGS[argv+1])) end end end 
  d end
```




```julia
oo(i) = println(o(i)) 
```




```julia
function o(i)  
  s,pre="$(typeof(i)){",""
  for f in sort!([x for x in fieldnames(typeof(i)) if !("$x"[1] == '_')])
    s   = s * pre * "$f=$(getfield(i,f))"
    pre = ", " end
  s * "}" end 
```




```julia
eg=Dict()
```




```julia
go(arg) = [run(s) for (s,_) in eg if arg == split(s)[1]]  
```




```julia
function run(s,fun=eg[s]) 
  global the 
  b4 = deepcopy(the) 
  global rseed = the.seed
  if (out = fun() == false) println("❌ FAIL : $s") end
  the = deepcopy(b4)
  out end
```




```julia
function runs() 
  global the
  the = cli(the)
  if the.help 
    println(about,"\n\n","ACTIONS:") 
    [println("  ./up.jl  $s") for s in sort([s for (s,_) in eg])]
  else        
    [go(arg) for arg in ARGS] end  end
```




```julia
eg["boom   : handle a crash"] = function() false end
```




```julia
eg["sets   : show the settings"] = function() println(the) end
```




```julia
eg["csv    : print rows in csv file"] = function()  
  csv(the.file, (r) -> println(r)) end
```




```julia
eg["rand   : print random ints"] = function()
  global rseed=1; println(rani(1,10), " ", rnd(ranf(1,10),2))
         rseed=1; println(rani(1,10), " ", rnd(ranf(1,10),2)) end
```




```julia
eg["many   : print random items"] = function()   
  println(many([10,20,30],4)) end
```




```julia
eg["num    : print nums"] = function()
  v=[]
  incs!(v, [normal(10,2) for _ in 1:1000])
  sort!(v)
  9.8 < often(v) < 10.2 && 1.85 < spread(v) < 2.15 end
```




```julia
eg["sym    : print syms"] = function()
  d = Dict() 
  incs!(d, [c for c in "aaaabbc"])
  return 'a'==often(d) && 1.37 < spread(d) < 1.38  end
```




```julia
eg["data   : print data"] =  function()
  print(stats(DATA(the.file))) end
```




```julia
eg["d2h    : calculate distance to heaven"] = function()
  dt = DATA(the.file) 
  print(d2h(dt,dt.rows[1])) end
```




```julia
eg["order  : print order"] = function()
   dt    = DATA(the.file) 
   rows = sort(dt.rows, alg=InsertionSort, by=row -> d2h(dt,row))
   n    = length(rows)
   m    = int(n ^ .5)
   println("baseline ", stats(dt))
   println("best     ", stats(clone(dt,rows[1:m+1])))
   println("rest     ", stats(clone(dt,rows[n-m:n]))) end
```




```julia
if (abspath(PROGRAM_FILE) == @__FILE__) runs() end
```


