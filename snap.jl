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
COL(s::String) = occursin(r"^[A-Z]", s) ? [] : Dict() 

inc!(x, v::Vector) = begin [inc!(x,y) for y in v]; x end

inc!(v::Vector,x::Number) = push!(v,x)  
inc!(d::Dict,  x) = d[x] = get(d,x,0) + 1  

mid(v::Vector) = per(v, .5)
mid(d::Dict)   = findmax(d)[2]

div(v::Vector) = (per(v, .9) - per(v, .1))/2.46
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
@kwdef mutable struct Data rows=[]; cols=nothing end
@kwdef mutable struct Cols klass=nothing; all=[]; x=Dict(); y=Dict(); names=[] end  

DATA(src) = begin
  data1 = Data()
  src isa String ? csv(src, row -> data!(data1,row)) : [data!(data1,row) for row in src]  
  [sort(col) for col in data1.cols.all if col isa Vector]
  data1 end

data!(data1::Data, row::Vector) = begin
  if (data1.cols==nothing) data1.cols = COLS(row) else
    [inc!(col,x) for (col,x) in zip(data1.cols.all,row) if x != "?"]
    push!(row, data1.rows) end end

COLS(v::Vector{String}) = begin
  cols1 = Cols(names=v, all= [COL(s) for s in v])
  for (n,(s,col)) in enumerate(zip(v,cols1.all))
    if s[end] != "X" 
      if s[end] == "!" klass=col end
      (occursin(s[end],"!+-") ? cols1.y : cols1.x)[n] = col end end  
  cols1 end
 
clone(data1::Data, src=[]) = DATA( vcat([data1.cols.name],src) )

#---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ----------
make(s) = begin
  for t in [Int32,Float64,Bool] if ((x=tryparse(t,s)) != nothing) return x end end 
  s end

the=(;Dict(Symbol(k) => make(v) for (k,v) in eachmatch(r"\n.*--(\S+)[^=]+= *(\S+)",about))...)  

int(n::Number)         = floor(Int,n)

rseed=the.seed
rani(lo::Int, hi::Int)  = floor(Int, .5 + ranf(lo,hi))  
ranf(lo=0.0, hi=1.0) = begin
  global rseed = (16807 * rseed) % 214748347 
  lo + (hi - lo) * rseed / 214748347 end

any(v::Vector)         = v[rani(1,length(v))]
many(v::Vector,n::Int) = [any(v)  for _ in 1:n]

per(v::Vector,p=.5) = v[ max(1, int(p*length(v)))]

normal(mu,sd) = mu + sd*sqrt(-2*log(ranf())) * cos(2*π*ranf())

csv(sfile, fun::Function) = begin
  src = open(sfile)
  while ! eof(src)
    new = replace(readline(src), r"([ \t\n]|#.*)"=>"")
    if sizeof(new) != 0
      fun(map(make,split(new,","))) end end end

cli(settings::NamedTuple) = begin
  tmp = Dict()
  for (k,v) in pairs(settings) 
    s = String(k)
    tmp[k] = v
    for (argv,flag) in enumerate(ARGS)
      if (flag=="-"*s[1] || flag=="--"*s)
        tmp[k] = v==true ? false : (v==false ? true : make(ARGS[argv+1])) end end end
  (;tmp...) end

#---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ----------
@kwdef mutable struct Egs names=[]; funs=Dict() end
EGS=Egs()
eg(s,fun) = begin push!(EGS.names,s); EGS.funs[s] = fun end

runs() = begin
  global the = cli(the)
  if (the.help) 
    println(about,"\n\n","ACTIONS") 
    for s in EGS.names println("   julia snap.jl $s") end
  else
    [run(s,EGS.funs[s]) for arg in ARGS for s in EGS.names if arg == split(s)[1]] end end
    
run(s,fun) = begin
  global the
  b4 = deepcopy(the) 
  global rseed = the.seed
  if (out = fun() == false) println("❌  FAIL : $s") end
  the = deepcopy(b4)
  out end

#---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ----------
eg("sets\t: show the settings",  () -> 
  println(the)) 

eg("csv \t: print rows in csv file", () -> 
  csv(the.file, (r) -> println(r)))

eg("rani \t: print random ints", () ->  begin
  global rseed=1; print(    rani(1,10)," ",rani(1,10))
         rseed=1; println(" ",rani(1,10)," ",rani(1,10)) end)

eg("ranf \t: print random floats", () ->  begin
  global rseed=1; print(    ranf()," ",ranf())
         rseed=1; println(" ",ranf()," ",ranf()) end)

eg("many \t: print random items",  () ->  
  println(many([10,20,30],4)))

eg("num  \t: print nums", () -> begin
  v=[]
  inc!(v, [normal(10,2) for _ in 1:1000])
  sort!(v)
  println(9.8 < mid(v) < 10.2)
  println(1.85 < div(v) < 2.15) end)

#---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ----------
if (abspath(PROGRAM_FILE) == @__FILE__) runs() end