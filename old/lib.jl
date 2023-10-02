# vim: set et sts=3 sw=3 ts=3 :
using Parameters
using ResumableFunctions

rseed=937162211
function rani(nlo, nhi)  int(.5 + ranf(nlo,nhi)) end
function ranf(nlo=0, nhi=1) 
  global rseed = (16807 * rseed) % 214748347 
  nlo + (nhi - nlo) * rseed / 214748347 end

int(n)    = floor(Int,n)
any(a)    = a[ rani(1,length(a))  ]
many(a,n) = [any(a)  for _ in 1:n]

function coerce(x)
  for thing in [Int32,Float64,Bool]
    if (y=tryparse(thing,x)) != nothing return y end end 
  x end 

@resumable function csv(sfile)
  src = open(sfile)
  while ! eof(src)
    new = replace(readline(src), r"([ \t\n]|#.*)"=>"")
    if sizeof(new) != 0
      @yield map(coerce,split(new,",")) end end  end

function settings(s; update=false)
   function cli(k,v)
      for (i,flag) in enumerate(ARGS)
         if update && (flag=="-"*k[1] || flag=="--"*k)
            v= v=="true"  ? "false" : (v=="false" ? "true" : ARGS[i+1]) end end 
      Symbol(k) => coerce(v) end 
   pat = r"\n *-[^-]+--(\S+)[^=]+= *(\S+)"
   d   = Dict(cli(k,String(v)) for (k,v) in eachmatch(pat,s))
   ((;d...), s) end # Julia idiom. Coerces a dictionary to a named tuple

oo(x) = println(o(x))

o(i::AbstractString) = i 
o(i::Bool)       = string(i) 
o(i::Char)       = string(i) 
o(i::Number)     = string(round(i;digits=2))
o(i::Array)      = "["*join(map((x) -> o(x),i),", ")*"]" 
o(i::NamedTuple) = "{"*join(["$k="*o(v) for (k,v) in pairs(i)],", ")*"}" 
o(i::Dict)       = "{"*join(["$k="*o(v) for (k,v) in sort(i)],", ")*"}" 
o(i::Any)        = begin
  s, pre="$(typeof(i)){", ""
  for f in sort([x for x in fieldnames(typeof(i)) 
                  if ("$x"[1] != '_')])
      s = s * pre * "$f=$(o(getfield(i,f)))"
      pre=", " end
  return s * "}" end

function tests(funs...)
  function show(s,c) printstyled(s;bold=true,color=c) end
  global the,help = settings(help;update=true)
  global rseed
  fails = 0
  if the.help
    println(help)
  else 
    cache = deepcopy(the)
    for fun in funs
      k = string(fun)
      if k==the.go || the.go=="all"
        show(">> $k ",:blue)
        pass, rseed = true, the.seed
        try pass = fun()
        catch e
          @error "E> " exception=(e, catch_backtrace())
          pass = false 
        finally 
          the = deepcopy(cache) 
        end
        if pass != false show("PASS\n",:light_green) 
        else show("FAIL\n",:light_red)
             fails += 1 end end end end 
  fails end 
