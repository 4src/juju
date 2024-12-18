Str,Fun = AbstractString,Function
Atom    = Union{Symbol,Number,Char,Bool,Str}
Big     = 1E32

csv(src::IOStream, fun::Fun) = 
  while ! eof(src)
    new = replace(readline(src), r"([ \t\n]|#.*)"=>"")
    if sizeof(new) != 0
      fun(map(coerce,split(new, ","))) end end

oo(x)            = println(o(x)) 

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