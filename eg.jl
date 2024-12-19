include("kpp.jl")

go=Dict()

go["--nums"] = () -> 
  for r in [20,40,80,160,320,640,1280]
    num=adds([normal(20,1) for _ in 1:r]) 
    println((r, [round(x, digits=3) for x in [num.mu, num.sd]])) end 

go["--syms"] = () ->
  sym = adds(split("aaaabbc"), i=Sym())

go["--csv"] = () -> 
  csv(open("data/auto93.csv"), oo)

go["--cols"] = () -> 
  for x in make(Cols(), ["Clndrs", "Vol", "HpX", "Lbs-", 
                          "Acc+", "Model", "origin", "Mpg+"]).y
     oo(x) end

go["--data"] = () -> 
  print(adds(Data(),the.data))

go["--boom"] = () -> false 

go["--oo"] = () -> begin
  oo(Num(txt="fred-",mu=0.333333))
  oo([1,2,3,4])
  oo(1)
  oo(the) end

[go[s]() for s in ARGS if s in keys(go)] 

