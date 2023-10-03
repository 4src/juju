# using StackTraces
#
# function test1()
#   x=1
#   try
#     print(x/a)
#   catch
#       stacktrace(catch_backtrace())
#   end end
#
#o

function getproperty(x::Dict{String, Int64}, f::Symbol)
    print(1)
    get(x,f)
end


d=Dict("a"=>1, "b"=>2)
print(d.a)

function tests1(k,fun)
    print("⚠️a $k")
    if fun() println(" ✅"); 0 else  println(" ❌"); 1 end end 
    print(1)
    exit(5)
#
# function tests(a)
#     global the,help,rseed
#     fails = 0
#     b4    = deepcopy(the)
#     if the.help
#         print(help)
#     else
#         for (k,fun) in pairs(a)
#             if the.help==k || then.help=="all" 
#                rseed = the.seed
#                the   = deepcopy(b4)
#                print("⚠️a $k")
#                if fun() println(" ✅")
#                else     println(" ❌"); fails += 1 end end end
#
#     catch e
#         @error "Something went wrong" exception=(e, catch_backtrace())
#     end end
#
test2()
