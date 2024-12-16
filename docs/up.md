<img src="https://img.shields.io/badge/tests-passing-green"> <img
src="https://img.shields.io/badge/julia-1.10.1-yellow"> <img
src="https://img.shields.io/badge/purpose-se--ai-blueviolet"> <img
src="https://img.shields.io/badge/platform-osx,linux-pink">

<img src="https://img.shields.io/badge/tests-passing-green"> <img
src="https://img.shields.io/badge/julia-1.10.1-yellow"> <img
src="https://img.shields.io/badge/purpose-se--ai-blueviolet"> <img
src="https://img.shields.io/badge/platform-osx,linux-pink">

<img src="https://img.shields.io/badge/tests-passing-green"> <img
src="https://img.shields.io/badge/julia-1.10.1-yellow"> <img
src="https://img.shields.io/badge/purpose-se--ai-blueviolet"> <img
src="https://img.shields.io/badge/platform-osx,linux-pink">

<img src="https://img.shields.io/badge/tests-passing-green"> <img
src="https://img.shields.io/badge/julia-1.10.1-yellow"> <img
src="https://img.shields.io/badge/purpose-se--ai-blueviolet"> <img
src="https://img.shields.io/badge/platform-osx,linux-pink">

# Up.jl : simple incremental sequential optimization

Life is short and there is too much to see.
So how do we make intelligent decisions,
in the face of limited knowledge?

To say that another way, we are trying to learn a model
$f$ such that we can predict $y=f(x)$ where $y$ are goals
and $x$ are the model inputs.  In many real-world scenarios,
we can find lots of $x$ candidates, but it it is too expensive or
slow to find all their associated $y$ values. So we need to learn
$f$ using lots of $x$ and only a few $y$ labels.

Sequential model optimizers (SMO) label a few examples,  then take
a guess at what $f$ might be. This guess is then quickly
applied to lots of  $x$ values to find guesses for their $y$ labels.  The item with most interesting guess is then labelled,
$f$ is updated, and the cycle repeats.

Often, SMO builds its models using complex algorithms
(e.g. Gaussian process models [^google]). This code is an
experiment if a much simpler approach works (based on a N&auml;ive
Bayes classifier).

## Multi-Objective Optimization
To support multi-objective optimization, this code sorts items by
`distance to heaven`; i.e. the Euclidean distance of all the
$f$ values to  `heaven` (the ideal values for each goal).

```julia <up d2h>

```

## Data Model
### Columns are `Num`s or `Sym`s
For the above `d2h`  code to  work, when we read in a csv data file, we need to fill in some  details  like: 

- what are the $y$ values (used in `data.cols.y`) 
- (b) what is heaven for each $y$ goal (used in `col.heaven`). 

To make that work, the column names (on line one
of the csv file) have some special syntax:

- Any column name starting with an upper-case letter (like `Age`) is a `Num`eric;
- Any column name ending with `+`,`-` is a $y$ goal to be maximized
  or minimized (respectively);
- For $y$ goals we want to minimize/maximize, `Heaven` is 0,1.

```julia <up col>

```
In the above, `Sym` and `Num` are `s`and `n` are the name of the column and its column number.
`Num`s and `Sym`s handle numeric and symbolic columns, respectively. 

```julia <up numsym>

```
Inside `Sym`, `has` stores the frequency counts of symbols in a column.
And inside `Num`, we calculate `sd` incrementally using `n`,`mu` and the
second moment variable `m2`-- via the Welford algorithn  [^welford] (which
computes `sd` without needing two passes).

```julia <up add!>

```
### `Data` stores columns and rows
When we read in a csv, its rows get added to a `Data` type. As we do, the `Num` and `Sym` cols are incrementally updated.   These columns
are kept in multiple lists:

- `all` is all the columns;
- `x`,`y` are the independent and dependent columns;

```julia <up data>

```

```julia <up data!>

```
### `Data` comes from  csv files, or other `Data`

```julia <up options>
options="
up.jl: smos
(c)2024 Tim Menzies <timm@ieee.org>, BSD-2 license

OPTIONS:
  -b --bins   initial number of bins   = 16
  -C --Cohen  too small                = .35
  -f --file   csv data file            = data/auto93.csv
  -F --Far    how far to look          = .95
  -h --help   show help                = false
  -H --Half   where to find for far    = 256
  -m --min    min size                 = .5
  -p --p      distance coefficient     = 2
  -r --reuse  do npt reuse parent node = true
  -s --seed   random number seed       = 1234567891"
#------------------------------------------------------------------------------
@kwdef mutable struct Num
  at=0; txt=""; n=0; mu=0; m2=0; sd=0; lo=1E-30; hi= -1E-30; heaven=1 end

@kwdef mutable struct Sym
  at=0; txt=""; n=0; has=Dict() end

@kwdef mutable struct Data rows=[]; cols=nothing end

@kwdef mutable struct Cols 
  names=[]; klass=nothing; all=[]; x=[]; y=[]; end
#------------------------------------------------------------------------------
COL(s=" ", n=0) = (occursin(r"^[A-Z]", s) ? NUM : SYM)(s,n) 
SYM(s=" ", n=0) = Sym(at=n, txt=s, has = Dict()) 
NUM(s=" ", n=0) = Num(at=n, txt=s, heaven= s[end]=="-" ? 0 : 1)

function add!(sym::Sym, x) sym.n += 1; sym.has[x] = 1 + get(sym.has,x,0) end 
function add!(num::Num, x::Number) 
  num.n  += 1
  d       = x - num.mu
  num.mu += d / num.n
  num.m2 += d * (x -  num.mu)
  num.sd  = num.n < 2 ? 0 : (num.m2 / (num.n - 1))^.5
  num.lo  = min(x, num.lo)
  num.hi  = max(x, num.hi) end

often(num::Num) = num.mu
often(sym::Sym) = findmax(sym.has)[2]

spread(num::Num) = num.sd
spread(sym::Sym) = - sum(n/sym.n*log2(n/sym.n) for (_,n) in sym.has if n>0) 

norm(_, x)  = x 
norm(num::Num, x::Number) = (x - num.lo) / (num.hi - num.lo + 1E-30)
#------------------------------------------------------------------------------
function COLS(v::Vector) 
  cols = Cols(names=v, all= [COL(s,n) for (n,s) in enumerate(v)])
  for (n,(s,col)) in enumerate(zip(v, cols.all))
    if s[end] != "X" 
      if s[end] == "!" klass=col end
      push!(occursin(s[end], "!+-") ? cols.y : cols.x, col) end end  
  cols end
 
#------------------------------------------------------------------------------
DATA(x) = adds!(Data(),x)

adds!(x, lst)           = begin [add!(x,y) for y in lst]; x end
adds!(data::Data, file) = begin csv(file, r->add!(data,r)); data end

function add!(data::Data, v::Vector) 
  if data.cols === nothing data.cols=COLS(v) else  
    [add!(col,x) for (col,x) in zip(data.cols.all, v) if x != "?"]
    push!(data.rows, v) end end

clone(data::Data, src=[]) = adds!(DATA(data.cols.names),src) 

function d2h(data::Data, v::Vector) 
  d = sum((col.heaven - norm(col, v[col.at])) ^ 2  for col in data.cols.y)
  (d/length(data.cols.y)) ^ .5 end

function stats(data::Data,):Dict
  Dict(col.txt => often(col) for col in data.cols.x) end
  
#------------------------------------------------------------------------------
int(n::Number) = floor(Int,n)
rnd(x,n=3)     = round(x,sigdigits=n)

function what(s) 
  for t in [Int32,Float64,Bool] 
    if ((x=tryparse(t,s)) !== nothing) return x end end 
  s end
  
the=(;Dict(Symbol(k)=>what(v) 
      for (k,v) in eachmatch(r"\n.*--(\S+)[^=]+= *(\S+)",options))...)  

function csv(sfile, fun::Function) 
  src = open(sfile)
  while ! eof(src)
    new = replace(readline(src), r"([ \t\n]|#.*)"=>"")
    if sizeof(new) != 0
      fun(map(what,split(new,","))) end end end

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

shuffle!(v::Vector) = sort(v, by= _ -> rani(1,100000))

rseed=the.seed
function rani(lo::Int, hi::Int) int(.5 + ranf(lo,hi)) end
function ranf(lo=0.0, hi=1.0) 
  global rseed = (16807 * rseed) % 214748347 
  lo + (hi - lo) * rseed / 214748347 end

oo(i) = println(o(i)) 
function o(i)  
  s,pre="$(typeof(i)){",""
  for f in sort!([x for x in fieldnames(typeof(i)) if !("$x"[1] == '_')])
    s   = s * pre * "$f=$(getfield(i,f))"
    pre = ", " end
  s * "}" end 

#------------------------------------------------------------------------------
eg=Dict()

go(x) = [run(s) for (s,_) in eg if x == split(s,":")[1]]; nothing 

function run(s,fun=eg[s]) 
  print(s)
  global the 
  b4 = deepcopy(the) 
  global rseed = the.seed
  if (out = fun() == false) println("X FAIL : $s") end
  the = deepcopy(b4)
  out end

function main() 
  global the
  the = cli(the)
  if the.help 
    println(options,"\n\n","ACTIONS:") 
    for s in sort([s for (s,_) in eg])
      a = split(s,":")
      @printf "  ./up.jl  %-8s  # %s\n" a[1] a[2] end
  else        
    [go(arg) for arg in ARGS] end  end
 
#------------------------------------------------------------------------------
eg["boom: handle a crash"] = function() false end

eg["sets: show the settings"] = function() println(the) end

eg["csv: print rows in csv file"] = function() 
  n = 0
  csv(the.file, (r) -> n += length(r)) 
  n == 3192 end

eg["rand: print random ints"] = function()
  global rseed=1; i1 = rani(1,10); f1=rnd(ranf(1,10),2)
         rseed=1; i2 = rani(1,10); f2=rnd(ranf(1,10),2) 
         i1==i2 && f1==f2 end

eg["many: print random items"] = function()   
  println(shuffle!([10,20,30,40,50,60,70,80,90])) end

eg["num: print nums"] = function()
  n=adds!(NUM(), [norm(10,2) for _ in 1:1000])
  sort!(n)
  9.8 < often(n) < 10.2 && 1.85 < spread(n) < 2.15 end

eg["sym: print syms"] = function()
  d = adds!(SYM(), [c for c in "aaaabbc"])
  return 'a'==often(d) && 1.37 < spread(d) < 1.38  end

eg["data: print data"] =  function()
  print(stats(DATA(the.file))) end

eg["clone: print data"] =  function()
  dt = DATA(the.file)  
  print(clone(dt,dt.rows[1:50])) end

eg["d2h: calculate distance to heaven"] = function()
  dt = DATA(the.file) 
  print(d2h(dt,dt.rows[1])) end

eg["order: print order"] = function()
   dt    = DATA(the.file)  
   rows=sort(dt.rows, by=row -> d2h(dt,row)) 
   n    = length(rows)
   m    = int(n ^ .5)
   return println("baseline ", stats(dt))

   return println(100,":",length(rows),":",clone(dt,rows[1:m+1]))
   println("best     ", stats(clone(dt,rows[1:m+1])))
   println("rest     ", stats(clone(dt,rows[n-m:n]))) end
#-------------------------------------------------
if (abspath(PROGRAM_FILE) == @__FILE__) main() end
```

After that, the code:

<img align=right width=600 src="https://miro.medium.com/v2/resize:fit:846/1*und5wL5DogTb8zkyOaFmrA.png">

- Divide the `N` items into `todo` and `done`
  - where `done` is very small (say, 4)
  - and `todo` is all the rest.
- Label all the goals for eveything in `todo`.
- For a limited number of times do:
  - Sort `done` into `best` and `rest` (using `distance to heaven`);
  - Build a model that can recognize `best` and `rest`
    - Here we are use a simple Naive Bayes classifier.
  - For everything in `todo`,find the item that has
    - max likelihood of being in `best`;
    - and min likelihood of being in `rest`.
  - Move that item from `todo` to `done`, and label all its goals.

Return the best item in `best`.

This  code uses  two conventions:  

- This code uses a global `the` variable to store config information,
  extracted from the above `options` string.
- `xxx = XXX()` uses the `XXX()` constructor to create a variable of type `Xxx`.
  - e.g.  `sym = SYM()` creates `sym`, a variable of type `Sym`.

[^google]: Golovin, D., Solnik, B., Moitra, S., Kochanski, G., Karro, J., & Sculley, D. (2017, August). Google vizier: A service for black-box optimization. In Proceedings of the 23rd ACM SIGKDD international conference on knowledge discovery and data mining (pp. 1487-1495).

[^welford]: https://en.wikipedia.org/wiki/Algorithms_for_calculating_variance#Welford's_online_algorithm

:::

:::

