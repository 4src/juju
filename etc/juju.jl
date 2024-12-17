# vim: set et sts=2 sw=2 ts=2 :
include("lib.jl")
the,help = settings("
JUJU: multi-objective semi-supervised explabations in O(log(N)) time
(c) 2023 Tim Menzies <timm@ieee.org> BSD-2 license

USAGE:
  julia juju.jl [OPTIONS]

OPTIONS:
  -c --cohen   trivial is up to sd*cohen = 0.35
  -f --file    where to get data         = ../data/auto93.csv
  -g --go      start up action           = nothing
  -h --help    show help                 = false 
  -s --seed    random number seed        = 937162211")

@with_kw mutable struct ROW
  cells=[]; id=0; klass=nothing end

  (i::ROW)(col) = begin println("asdas",o(col)); i.cells[col.pos]  end

@with_kw mutable struct DATA
  rows=[]; cols=nothing end

@with_kw mutable struct NUM
  pos=0; txt=""; n=0;
  w=1; lo=10.0^64; hi=-10.0^64
  mu=0; m2=0 end

@with_kw mutable struct SYM
  pos=0; txt=""; n=0; w=1;
  has=Dict();  most=0; mode=nothing end

function COL(pos, txt, inits=[], by=identity)
  x = occursin(r"^[A-Z]", txt) ? NUM : SYM
  x(pos=pos, txt=txt, w= occursin(r"-$",txt) ? -1 : 1) 
  [inc!(x,by(y)) for y in inits]
  x end

function COLS(a)
  names,all,x,y,klass = a,[],[],[],nothing
  for (pos,txt) in enumerate(a)
    col = COL(pos,txt)
    push!(all, col)
    if !occursin(r"X$", txt)
      push!(occursin(r"[!\-\+]$", txt) ? y : x, col) 
      if occursin(r"!$", txt) klass=col end end end
  (names=names, all=all, x=x, y=y, klass=klass)  end  

function inc!(i,x,inc=1)
  if x != "?"
    i.n += inc; inc1!(i,x,inc) end end

function inc1!(i::NUM,n,_)
  i.lo  = min(i.lo, n)
  i.hi  = max(i.hi, n)
  d     = n - i.mu
  i.mu += d / i.n
  i.m2 += d * (n - i.mu) end

function inc1!(i::SYM,s,inc=1)
  now = i.has[s] = get(i.has,s,0) + inc
  if now > i.most
    i.mode, i.most = s, now end end

rnd(i::NUM,x,digits=2) = round(x, digits=2)
rnd(i::SYM,x,_)        = x

mid(i::NUM) = i.mu
mid(i::SYM) = i.mode

div(i::SYM) = -sum((n/i.n*log2(n/i.n) for (_,n) in i.has))
div(i::NUM) = i.m2<0 ? 0 : (i.n<2 ? 0 : (i.m2 / (i.n - 1))^0.5) 

norm(i::NUM,n) = n=="?" ? n : (n - i.lo)/(i.hi - i.lo + 1E-16)

function holds(on, also=[]) 
  i = DATA()
  holds1(i,on)
  [row(i,x) for x in also]
  i end

holds1(i::DATA, on::String) = [row(i,x) for x in csv(on)]
holds1(i::DATA, on::DATA)   = row(i, on.cols.names)
holds1(i::DATA, on)         = [row(i,x) for x in on]

_id=0
function row(i::DATA, a)  
  if  isnothing(i.cols)
    i.cols=COLS(a) 
  else
    global _id = _id + 1
    row(i, ROW(cells=a,id=_id)) end end

function row(i::DATA, row1::ROW)  
  push!(i.rows, row1)  
  for cols in [i.cols.x, i.cols.y] 
    for col in cols
      inc!(col, row1(col)) end end end

function stats(i::DATA; cols=i.cols.y, fn=mid, digits=3)
  d=Dict(col.txt=>rnd(col,fn(col),digits) for col in cols)
  d["n"] = length(i.rows)  
  d end

function better(i::DATA, r1::ROW, r2::ROW)
  s1, s2, n = 0, 0, length(i.cols.y)
  for col in i.cols.y
    x,y = norm(col, r1(col)), norm(col, r2(col))
    s1 -= exp(col.w * (x-y)/n)
    s2 -= exp(col.w * (y-x)/n) end
  return s1/n < s2/n end

# function chop(a,x)
#   xs = COL(txt=x.txt,pos=x.pos, inits=a, by=x)
#   eps = the.cohen * div(xs)
#   m = length(a)
#   tmp,out, n =  xy(), m / the.div.divs
#   last=nothing
#   for (i,one) in enumerate(a)
#     if tmp.x.n>=n && m - i > n && one(x) != last(x) 
#       if x(one) - x(tmp[1]) > eps
#         push!(out, tmp)
#         tmp = xy() end end
#     add!(tmp, one)
#     last =one  end
#   if length(tmp.x.n) > 0 push!(out,tmp) end
#   out end
#
# function bins(lst, x, y)
#   function xy() (rows= [], 
#                  x   = COL(pos=x.pos,txt=x.txt), 
#                  y   = COL(pos-y.ps,txt=y.txt)) end
#   function add!(xy,row)
#      inc!(xy.x,row(x))
#      inc!(xy.y,row(y))
#      push!(xy.rows, row) end
#   function merge(a)
#     tmp, out, j, m = [], [], 1, length(a)
#     while j <= m
#       one = a[j]
#       if j < m
#         two       = a[j+1]
#         three     = [ one ; two ]
#         n1, n2, n3= length(one), length(two), length(three)
#         sd1,sd2,sd3= sd(one,y), sd(two,y), sd(three,y)
#         sd12      = n1/n3*sd1 + n2/n3*sd2
#         if abs(sd1 - sd2) < 0.01 || sd12*the.div.trivial >sd3
#           one = three
#           j += 1 end end
#       push!(tmp,one)
#       j += 1 end
#     return length(tmp) == length(a) ? a : merge(tmp)  
#   end #---------------------------
#   merge(chop( sort([z for z in lst if x(z) != "?"], by=x) ))
# end
