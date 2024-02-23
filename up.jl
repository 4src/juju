#!/usr/bin/env julia --compile=min --optimize=0

"---
Given `N` items to explore, and not enough time to label them all,
find just enough goal labels to build a model that selects for the better items.
To support multi-objective optimization, this code sorts items by
`distance to heaven`; i.e. the Euclidean distance of an item's multiple
goal labels to `heaven` (the ideal values for each goal).
After that, the code:
   
<img align=right width=600
     src='https://miro.medium.com/v2/resize:fit:846/1*und5wL5DogTb8zkyOaFmrA.png'>
       
-  Divide the `N` items into `todo` and `done` 
   - where `done` is very small (say, 4)
   - and `todo` is all the rest.
-  Label all the goals for eveything in `todo`.
-  For a limited number of times do:
   - Sort `done` into `best` and `rest` (using `distance to heaven`); 
   - Build a model that can recognize `best` and `rest`
     - Here we are use a simple Naive Bayes classifier.
   - For everything in `todo`,find the item that has
     - max likelihood of being in `best`;
     - and min likelihood of being in `rest`.
   - Move that item from `todo` to `done`, and label all its goals. 
   
Return the best item in `best`."

options="
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

"This  code uses  two conventions:  
     
- This code uses a global `the` variable to store config information,
  extracted from the above `options` string.
- `xxx = XXX()` uses the `XXX()`` constructor to create a variable of type `Xxx``.
  - e.g.  `sym = SYM()`` creates `sym`, a variable of type `Sym``."

"# Types
  
`Num`= Numeric columns."

@kwdef mutable struct Num
  at=0; txt=""; n=0; mu=0; m2=0; sd=0; lo=1E-30; hi= -1E-30; heaven=1 end

"`Sym` = Symbolic columns."

@kwdef mutable struct Sym
  at=0; txt=""; n=0; has=Dict() end

"`Cols` = Factory for making and storing `Num`s or `Sym`s."

@kwdef mutable struct Cols 
  klass=nothing; all=[]; x=Dict(); y=Dict(); names=[] end

"`Data` = storage for rows and cols."

@kwdef mutable struct Data rows=[]; cols=nothing end

"# Columns
Column constructors."

COL(s=" ",n=0) = (occursin(r"^[A-Z]", s) ? NUM : SYM)(s,n) 
SYM(s=" ",n=0) = Sym(at=n, txt=s) 
NUM(s=" ",n=0) = Num(at=n, txt=s, heaven= s[end]=="-" ? 0 : 1)

"Column updates."

function add!(sym::Sym, x) sym.n+=1; sym.has[x]=1+get(sym.has,x,0) end 
function add!(num::Num, x::Number) 
  num.n += 1
  d     = x - num.mu
  num.mu += d / num.n
  num.m2 += d * (x -  num.mu)
  num.sd  =  num.n > 1 ? (num.m2 / (num.n - 1))^.5 : 0
  num.lo = min(x, num.lo)
  num.hi = max(x, num.hi) end

"Column middle values."

often(num::Num) = num.mu
often(sym::Sym) = findmax(sym.has)[2]

"Column deviation from middle."

spread(num::Num) = num.sd
spread(sym::Sym) = - sum(n/sym.n*log2(n/sym.n) for (_,n) in sym.has if n>0) 

"Normalization."

norm(_, x)  = x 
norm(num::Num, x::Number) = (x - num.lo) / (num.hi - num.lo + 1E-30)

"Columns factor."

function COLS(v::Vector) 
  cols = Cols(names=v, all= [COL(s,n) for (n,s) in enumerate(v)])
  for (n,(s,col)) in enumerate(zip(v,cols.all))
    if s[end] != "X" 
      if s[end] == "!" klass=col end
      push!(occursin(s[end],"!+-") ? cols.y : cols.x, col) end end  
  cols end

"# Data"

DATA(x) = adds!(Data(),x)

"Add to `DATA`."

adds!(x, lst)           = begin [add!(x,y) for y in lst]; x end
adds!(data::Data, file) = begin csv(file, r->add!(data,r)); data end

function add!(data::Data, v::Vector) 
  if data.cols === nothing data.cols=COLS(v) else  
    [add!!(col,x) for (col,x) in zip(data.cols.all, v) if x != "?"]
    push!(data.rows, v) end end

"Generate a similar structure."

clone(data::Data, src=[]) = adds!(DATA([data.cols.names]),src) 

"Distance to heaven."

function d2h(data::Data, v::Vector) 
  d,n  = 0,0
  for (n,col) in data.cols.y 
    d += (col.heaven - norm(col, v[col.at])) ^ 2 
    n += 1 end 
  (d/n) ^ .5 end

"# General Utilities"

"Coerce to integer."

int(n::Number) = floor(Int,n)

"Round to (say) 3 digits."

rnd(x,n=3)     = round(x,sigdigits=n)

"Coerce strings to some type."

function what(s) 
  for t in [Int32,Float64,Bool] 
    if ((x=tryparse(t,s)) !== nothing) return x end end 
  s end

"Parse `options` to build `the` global settings."

the=(;Dict(Symbol(k)=>what(v) 
      for (k,v) in eachmatch(r"\n.*--(\S+)[^=]+= *(\S+)",options))...)  

"Randomly sort a list."

shuffle!(v::Vector) = sort(v, by= _ -> rani(1,100000))

"Generate random numbers based on `rseed`."

rseed=the.seed
function rani(lo::Int, hi::Int) int(.5 + ranf(lo,hi)) end
function ranf(lo=0.0, hi=1.0) 
  global rseed = (16807 * rseed) % 214748347 
  lo + (hi - lo) * rseed / 214748347 end

"Return one row per csv line."

function csv(sfile, fun::Function) 
  src = open(sfile)
  while ! eof(src)
    new = replace(readline(src), r"([ \t\n]|#.*)"=>"")
    if sizeof(new) != 0
      fun(map(what,split(new,","))) end end end

"Update named fields from command-line."

function cli(nt::NamedTuple) 
  (;cli(Dict(pairs(nt)))...) end

"Update  the dictionary field `xx` from any
CLI flaog `-x`. If the old field is a boolean,
we do not need an argument (we just swith the old value."

function cli(d::Dict) 
  for (k,v) in d 
    s=String(k) 
    for (argv,flag) in enumerate(ARGS)  
      if flag in ["-"*s[1],  "--"*s] 
        d[k] = v==true  ? false : (
               v==false ? true  : what(ARGS[argv+1])) end end end 
  d end

"Pretty print."

oo(i) = println(o(i)) 

"Print with sorted fields, ignoring private fields
(those starting with `_`."

function o(i)  
  s,pre="$(typeof(i)){",""
  for f in sort!([x for x in fieldnames(typeof(i)) if !("$x"[1] == '_')])
    s   = s * pre * "$f=$(getfield(i,f))"
    pre = ", " end
  s * "}" end 

"# Unit Tests (and Demos)
Store tests in `eg`:"

eg=Dict()

"Run some test whose label starts with `x`."

go(x) = [run(s) for (s,_) in eg if x == split(s)[1]]  

"Before running  a test, stash the config and reset the random number generator.
After running them, ensure the config is reset to the stash."

function run(s,fun=eg[s]) 
  global the 
  b4 = deepcopy(the) 
  global rseed = the.seed
  if (out = fun() == false) println("X FAIL : $s") end
  the = deepcopy(b4)
  out end

"Upate the global options from the command line. Maybe print the help or run the tests."

function main() 
  global the
  the = cli(the)
  if the.help 
    println(options,"\n\n","ACTIONS:") 
    [println("  ./up.jl  $s") for s in sort([s for (s,_) in eg])]
  else        
    [go(arg) for arg in ARGS] end  end

"### Demos"

eg["boom   : handle a crash"] = function() false end

eg["sets   : show the settings"] = function() println(the) end

eg["csv    : print rows in csv file"] = function() 
  n = 0
  csv(the.file, (r) -> n += length(r)) 
  n == 3192 end

eg["rand   : print random ints"] = function()
  global rseed=1; i1 = rani(1,10); f1=rnd(ranf(1,10),2)
         rseed=1; i2 = rani(1,10); f2=rnd(ranf(1,10),2) 
         i1==i2 && f1==f2 end

eg["many   : print random items"] = function()   
  println(shuffle!([10,20,30,40,50,60,70,80,90])) end

eg["num    : print nums"] = function()
  v=[]
  incs!(v, [normal(10,2) for _ in 1:1000])
  sort!(v)
  9.8 < often(v) < 10.2 && 1.85 < spread(v) < 2.15 end

eg["sym    : print syms"] = function()
  d = Dict() 
  incs!(d, [c for c in "aaaabbc"])
  return 'a'==often(d) && 1.37 < spread(d) < 1.38  end

eg["data   : print data"] =  function()
  print(stats(DATA(the.file))) end

eg["d2h    : calculate distance to heaven"] = function()
  dt = DATA(the.file) 
  print(d2h(dt,dt.rows[1])) end

eg["order  : print order"] = function()
   dt    = DATA(the.file) 
   rows = sort(dt.rows, alg=InsertionSort, by=row -> d2h(dt,row))
   n    = length(rows)
   m    = int(n ^ .5)
   println("baseline ", stats(dt))
   println("best     ", stats(clone(dt,rows[1:m+1])))
   println("rest     ", stats(clone(dt,rows[n-m:n]))) end

"# Start-up"

if (abspath(PROGRAM_FILE) == @__FILE__) main() end
