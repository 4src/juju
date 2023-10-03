about="
snap.jl: a fast way to find good options
(c) Tim Menzies <timm@ieee.org>, BSD-2 license

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
#---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ----------  
COL(s) = occursin(r"^[A-Z]", s) ? [] : Dict() 

incs!(x, v::Vector)       = begin  [inc!(x,y) for y in v]; x end

inc!(v::Vector,x::Number) = push!(v,x)  
inc!(d::Dict,  x)         = d[x] = get(d,x,0) + 1 

mid(v::Vector) = per(v, .5)
mid(d::Dict)   = findmax(d)[2]

div(v::Vector) = (per(v, .9) - per(v, .1))/2.56
div(d::Dict)   = begin
  N = sum(n for (_,n) in d if n>0)
  - sum(n/N*log2(n/N) for (_,n) in d if n>0) end

norm(v::Vector, n::Number) = (n - v[1]) / (v[end] - v[1] + 1E-30)
norm(_, x) = x
 
dist(d::Dict,  x,y) = (x=="?" && y=="?") ? 1 : (x==y ? 0 : 1)  
dist(v::Vector,x,y) = begin
  if (x=="?" && y=="?") 1 else
    x,y = norm(v,x), norm(v,y)
    if x=="?" x = (y < .5 ? 1 : 0) end
    if y=="?" y = (x < .5 ? 1 : 0) end 
    abs(x - y) end end

#---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- 
@kwdef mutable struct Cols klass=nothing; all=[]; x=Dict(); y=Dict(); names=[] end  
COLS(v::Vector) = begin
  cl = Cols(names=v, all= [COL(s) for s in v])
  for (n,(s,col)) in enumerate(zip(v,cl.all))
    if s[end] != "X" 
      if s[end] == "!" klass=col end
      (occursin(s[end],"!+-") ? cl.y : cl.x)[n] = col end end  
  cl end

cols!(cl::Cols, row::Vector) = begin
  [inc!(col,x) for (col,x) in zip(cl.all,row) if x != "?"]
  row end
  
#---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ----------  
@kwdef mutable struct Data rows=[]; cols=nothing end

DATA(src) = begin
  dt = Data() 
  src isa Vector ? [data!(dt,row) for row in src] : csv(src, row -> data!(dt,row))  
  [sort!(col) for col in dt.cols.all if col isa Vector]
  dt end

data!(dt::Data, row::Vector) = 
  dt.cols==nothing ?  dt.cols = COLS(row) : push!( dt.rows, cols!(dt.cols,row))  

clone(dt::Data, src=[]) = DATA( vcat([dt.cols.names],src) )

stats(dt::Data, cols=nothing, want=mid, digits=2) = begin
  cols = cols==nothing ? dt.cols.y : cols
  d = Dict("N"=> length(dt.rows))
  for (n,col) in cols d[dt.cols.names[n]] = round(want(col), sigdigits=digits) end
  d end 

d2h(dt::Data, row) = begin
  d,m  = 0,0
  for (n,col) in dt.cols.y 
    w  = dt.cols.names[n][end] == '-' ? 0 : 1
    d += (w - norm(col, row[n])) ^ 2 
    m += 1 end 
  (d/m) ^ .5 end

dist(dt::Data, row1,row2) = begin
  d = m = 0
  for (n,col) in dt.cols.x
    d += dist(col, row1[n], row2[n]) ^ the.p
    m += 1 end
  (d/m) ^ (1/the.p) end

around(dt::Data,row1,rows=nothing) = begin
  rows = map(row2 -> (dist(dt,row1,row2), row2),rows == nothing ? dt.rows : rows)
  map(two -> two[2], sort(rows,  by= two -> two[1])) end 

#---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ----------
rnd(x,n=3)             = round(x,sigdigits=n)
normal(mu,sd)          = mu + sd*sqrt(-2*log(ranf())) * cos(2*π*ranf())
int(n::Number)         = floor(Int,n)
any(v::Vector)         = v[rani(1,length(v))]
per(v::Vector,p=.5)    = v[ max(1, int(p*length(v)))]
many(v::Vector,n::Int) = [any(v)  for _ in 1:n]

what(s) = begin
  for t in [Int32,Float64,Bool] if ((x=tryparse(t,s)) != nothing) return x end end 
  s end

the=(;Dict(Symbol(k) => what(v) for (k,v) in eachmatch(r"\n.*--(\S+)[^=]+= *(\S+)",about))...)  

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
        d[k] = v==true ? false : (v==false ? true : what(ARGS[argv+1])) end end end
  d end

#---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ----------
@kwdef mutable struct Egs names=[]; funs=Dict() end
EGS=Egs()
eg(s,fun) = begin push!(EGS.names,s); EGS.funs[s] = fun end
go(arg)   = [run(s,EGS.funs[s]) for s in EGS.names if arg == split(s)[1]] 

run(s,fun) = begin 
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
    
#---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ----------
eg("boom  : test fail",  () -> 
  false)

eg("sets  : show the settings",  () -> 
  println(the)) 

eg("csv   : print rows in csv file", () -> 
  csv(the.file, (r) -> println(r)))

eg("rani  : print random ints", () ->  begin
  global rseed=1; print(    rani(1,10)," ",rani(1,10))
         rseed=1; println(" ",rani(1,10)," ",rani(1,10)) end)

eg("ranf  : print random floats", () ->  begin
  global rseed=1; print(    ranf()," ",ranf())
         rseed=1; println(" ",ranf()," ",ranf()) end)

eg("many  : print random items",  () ->  
  println(many([10,20,30],4)))

eg("num   : print nums", () -> begin
  v=[]
  incs!(v, [normal(10,2) for _ in 1:1000])
  sort!(v)
  9.8 < mid(v) < 10.2 && 1.85 < div(v) < 2.15 end)

eg("sym   : print syms", () -> begin
  d = Dict() 
  incs!(d, [c for c in "aaaabbc"])
  return 'a'==mid(d) && 1.37 < div(d) < 1.38  end)

eg("data   : print data", () ->  print(stats(DATA(the.file))))

eg("d2h    : calculate distance to heaven",()-> begin
  dt = DATA(the.file) 
  print(d2h(dt,dt.rows[1])) end)

eg("order  : print order", () -> begin
   dt    = DATA(the.file) 
   rows = sort(dt.rows, by=row -> d2h(dt,row)) 
   n    = length(rows)
   m    = int(n ^ .5)
   println("baseline ", stats(dt))
   println("best     ",stats(clone(dt,rows[1:m+1])))
   println("rest     ",stats(clone(dt,rows[n-m:n]))) end)

eg("dist  : print dist", () -> begin
   dt    = DATA(the.file) 
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

#---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ----------
if (abspath(PROGRAM_FILE) == @__FILE__) runs() end