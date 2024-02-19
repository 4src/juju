#!/usr/bin/env julia --compile=min --optimize=0
about="
tiny.jl: smo
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

@kwdef mutable struct Num
  at=0; txt=""; n=0; mu=0; m2-0; sd=0; 
  lo=1E-30; hi= -1E-30; heaven = 1 end
@kwdef mutable struct Sym
  at=0; txt=""; n=0; has=Dict() end
@kwdef mutable struct Cols 
  klass=nothing; all=[]; x=Dict(); y=Dict(); names=[] end  
@kwdef mutable struct Data rows=[]; cols=nothing end

COL(s,n) = (occursin(r"^[A-Z]", s) ? NUM : SYM)(s,n) 
SYM(s,n) = Sym(at=n, txt=s) 
NUM(s,n) = begin 
  num = Num(at=n, txt=s)
  num.heaven = s[end]=="-" ? 0 : 1
  num

adds!!(x, v::Vector) = begin [add!(x,y) for y in v]; x end

add!(sym::Sym, x) = begin sym.n+=1; sym.has[x]=get(sym.has,x,0) + 1 end
add!(num::Num, x::Number) = begin 
  n    += 1
  d     = x - num.mu
  num.mu += d / num.n
  num.m2 += d * (x -  num.mu)
  num.sd  =  num.n > 1 ? (num.m2 / (num.n - 1))^.5 : 0
  num.min = min(x, num.min)
  num.max = max(x, num.max) end

often(num::Num) = num.mu
often(sym::Sym) = findmax(sym.has)[2]

spread(num::Num) = num.sd
spread(sym::Sym) = begin
  N = sum(n for (_,n) in sym.has if n>0)
  - sum(n/N*log2(n/N) for (_,n) in sym.has if n>0) end

norm(_,x) = x
norm(num::Num, x::Number) = (x - num.lo]) / (num.hi - num.lo + 1E-30)
#-------- --------- --------- --------- --------- --------- ----
COLS(v::Vector) = begin
  cols = Cols(names=v, all= [COL(s) for s in v])
  for (n,(s,col)) in enumerate(zip(v,cols.all))
    if s[end] != "X" 
      if s[end] == "!" klass=col end
      push!(occursin(s[end],"!+-") ? cols.y : cols.x, col) end end  
  cols end
#-------- --------- --------- --------- --------- --------- ----
DATA(x) = adds!(Data(),x)

adds!(data::Data, v::Vector) = [add!(data,r) for r in x]
adds!(data::Data, file)      = csv(file, r->add!(data,r))

add!(data::Data, v::Vector) = 
  if data.cols==nothing data.cols=COLS(v) else  
    [add!!(col,x) for (col,x) in zip(data.cols.all, v) if x != "?"]
    push!(dt.rows, v  qasdv ) end 

clone(data::Data, src=[]) = adds!(DATA([data.cols.names]),src)

d2h(data::Data, v::Vector) = begin 
  d,n  = 0,0
  for (n,col) in data.cols.y 
    d += (col.heaven - norm(col, v[col.at])) ^ 2 
    n += 1 end 
  (d/n) ^ .5 end
#-------- --------- --------- --------- --------- --------- ----
what(s) = begin
  for t in [Int32,Float64,Bool]
    if ((x=tryparse(t,s)) != nothing) return x end end 
  s end

the=(;Dict(Symbol(k)=>what(v) 
           for (k,v) in eachmatch(r"\n.*--(\S+)[^=]+= *(\S+)",about))...)  

function l.shuffle(t,    u,j)
  j=rani(1,i)
  for i = #u,2,-1 do j=math.random(i); u[i],u[j] = u[j],u[i] end
  return u end
              
rseed=the.seed
rani(lo::Int, hi::Int) = int(.5 + ranf(lo,hi))  
ranf(lo=0.0, hi=1.0)   = begin
  global rseed = (16807 * rseed) % 214748347 
  lo + (hi - lo) * rseed / 214748347 end

csv(sfile, fun::Function) = begin
  src = open(sfile)
  while ! eof(src)
    new = replace(readline(src), r"([ \t\n]|#.*)"=>"")
    if sizeof(new) != 0
      fun(map(what,split(new,","))) end end end

cli(nt::NamedTuple) = (;cli(Dict(pairs(nt)))...)
cli(d::Dict) = begin
  for (k,v) in d 
    s=String(k) 
    for (argv,flag) in enumerate(ARGS) 
      if flag in ["-"*s[1],  "--"*s]
        d[k] = v==true  ? false : (
               v==false ? true  : what(ARGS[argv+1])) end end end
  d end

#-------- --------- --------- --------- --------- --------- ----
@kwdef mutable struct Egs bad=[]; funs=Dict() end

go(arg) = [run(s,EGS.funs[s]) for s in EGS.names if arg == split(s)[1]] 

run(s,fun=EGS.funs[split(s)[1]]) = begin 
  global the 
  b4 = deepcopy(the) 
  global rseed = the.seed
  if (out = fun() == false) println("❌ FAIL : $s") end
  the = deepcopy(b4)
  out end

runs() = 
  if the.help 
    global the = cli(the)
    println(about,"\n\n","ACTIONS:") 
    for s in EGS.names println("   julia snap.jl $s") end 
  else  
   [go(arg) for arg in ARGS] end

#-------- --------- --------- --------- --------- --------- ----
"test fail"
boom(_::Eg) = false

"show the settings"
settings(_::Eg)= println(the) 

"print rows in csv file"
csv(_::Eg) = csv(the.file, r -> println(r)))

"print random ints"
rand(_::Eg) =  
  global rseed=1; println(rani(1,10), " ", rnd(ranf(1,10),2))
         rseed=1; println(rani(1,10), " ", rnd(ranf(1,10),2)) end)

("many  : print random items",  () ->  
  println(many([10,20,30],4)))

eg("num   : print nums", () -> begin
  v=[]
  incs!(v, [normal(10,2) for _ in 1:1000])
  sort!(v)
  9.8 < often(v) < 10.2 && 1.85 < spread(v) < 2.15 end)

eg("sym   : print syms", () -> begin
  d = Dict() 
  incs!(d, [c for c in "aaaabbc"])
  return 'a'==often(d) && 1.37 < spread(d) < 1.38  end)

eg("data   : print data", () ->  print(stats(DATA(the.file))))

eg("d2h    : calculate distance to heaven",()-> begin
  dt = DATA(the.file) 
  print(d2h(dt,dt.rows[1])) end)

eg("order  : print order", () -> begin
   dt    = DATA(the.file) 
   rows = sort(dt.rows, alg=InsertionSort, by=row -> d2h(dt,row))
   n    = length(rows)
   m    = int(n ^ .5)
   println("baseline ", stats(dt))
   println("best     ", stats(clone(dt,rows[1:m+1])))
   println("rest     ", stats(clone(dt,rows[n-m:n]))) end)

eg("dist  : print dist", () -> begin
   dt = DATA(the.file) 
   i=1
   while i < length(dt.rows)
    println(rnd(dist(dt, dt.rows[1], dt.rows[i])), "\t", dt.rows[i])
    i += 60  end end)

eg("around  : print around", () -> begin
    dt    = DATA(the.file)  
    rows= around(dt,dt.rows[1])
    i=1
    while i < length(rows)
      println(rnd(dist(dt, dt.rows[1], rows[i])), "\t", rows[i])
      i += 60  end end )

#-------- --------- --------- --------- --------- --------- ----
if (abspath(PROGRAM_FILE) == @__FILE__) runs() end
