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
  for thing in [Int32,Float64,Bool] if (y=tryparse(thing,x)) != nothing return y end end 
  x end

the=(;Dict(Symbol(k) => coerce(v) 
          for (k,v) in eachmatch(r"\n *-[^-]+--(\S+)[^=]+= *(\S+)",help))...) 
#---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- -----------
rseed=the.seed
function rani(nlo, nhi)  floor(Int, .5 + ranf(nlo,nhi)) end
function ranf(nlo=0, nhi=1) 
  global rseed = (16807 * rseed) % 214748347 
  nlo + (nhi - nlo) * rseed / 214748347 end
#---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- -----------
function inc!(i,x)        if x != "?" inc1!(i,x) end end
function inc1(v::Vector,x) push!(v,x) end
function inc1(d::Dict, x)  d[s] = get(d,x,0) + 1 end


print(typeof([]))