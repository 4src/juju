include("kpp.jl")

go=Dict()

go["boom"] = () -> false 

go["o"] = () -> begin
  oo(Num(txt="fred-",mu=0.333333))
  oo([1,2,3,4])
  oo(1)
  oo(the) end

[go[s[3:end]]() for s in ARGS if s[3:end] in keys(go)] 

