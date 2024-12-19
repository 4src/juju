include("kpp.jl")

go=Dict()

go["--num"] = () -> begin
  n = Num()
  print(2) end

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

