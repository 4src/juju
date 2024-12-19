Str,Fun = AbstractString,Function
Atom    = Union{Symbol,Number,Char,Bool,Str}
Big     = 1E32

normal(mu,sd) = mu + sd*sqrt(-2*log(ranf())) * cos(2*π*ranf())

rseed=1234567891
rani(lo::Int, hi::Int) = int(.5 + ranf(lo,hi))  
ranf(lo=0.0, hi=1.0)   = begin
  global rseed = (16807 * rseed) % 214748347 
  lo + (hi - lo) * rseed / 214748347 end


#------------------------------------------------------------------------------
csv(src::IOStream, fun::Fun) = 
  while ! eof(src)
    new = replace(readline(src), r"([ \t\n]|#.*)"=>"")
    if sizeof(new) != 0
      fun(map(coerce,split(new, ","))) end end

#------------------------------------------------------------------------------
oo(x) = println(o(x)) 

o(i::Atom) = string(i)  
o(i::Array) = "[" * join(map(o,i),", ")*"]" 
o(i::NamedTuple) = 
  "(" * join(sort!([":$f $(o( getfield(i,f)))" for f in keys((i))])," ") * ")"
o(i::Any) = 
  "$(typeof(i)){" * join([
          ":$f $(o(getfield(i,f)))" for f in fieldnames(typeof(i))]," ") * "}" 

cli(nt::NamedTuple) = (;cli(Dict(pairs(nt)))...)
cli(d::Dict) = begin
  for (k,v) in d 
    s=String(k) 
    for (argv,flag) in enumerate(ARGS) 
      if flag in ["-"*s[1],  "--"*s]
        d[k]= v==true ? false : (
              v==false ? true : coerce(ARGS[argv+1])) end end end
  d end

function coerce(s)
  for t in [Int32,Float64,Bool] 
    x = tryparse(t,s) 
    if ! isnothing(x) return x end end 
  s end
