# vim: set et sts=2 sw=2 ts=2 :
using Random
using Test
include("juju.jl")

function coerced()
  typeof(coerce("true")) == typeof(true) end

function manyed()
  a= sort(many([1,2,3,4],20))
  return length(a)==20 && a[1] == 1 && a[end]==4 end

function csved() 
  n=0; for r in csv("../data/auto93.csv"); n=n+length(r) end
  n == 3192 end

function numed()
  num = NUM()
  [inc!(num,ranf()) for x in 1:10^4]
  return  .49 < mid(num) < .51  &&  .28 < div(num) < .32 end

function symed()
  sym = SYM()
  [inc!(sym,x) for x in "aaaabbc"]
  return mid(sym) == 'a' && 1.37 < div(sym) < 1.38 end

exit(tests(coerced,manyed,csved, numed,symed))

# tests((
#   libs = -> begin
#     ))
# #
# @testset "jujus" begin
#    @testset "libs" begin
#      n=0; for r in csv("../data/auto93.csv"); n=n+length(r) end
#      @test n==3192
#      @test typeof(coerce("true")) == typeof(true)
#       lst= sort(many([1,2,3,4],100))
#       @test 1 in lst && 4 in lst
#       println(the)
#       oo(Dict("a"=>1,"b"=>2))
#    end
#    @testset "nums" begin
#      ok()
#      num = NUM()
#      [inc!(num,ranf()) for x in 1:10^4]
#      @test .49 < mid(num) < .51 
#      @test .28 < div(num) < .32
#    end
#    @testset "syms" begin
#      sym = SYM()
#      [inc!(sym,x) for x in "aaaabbc"]
#      @test mid(sym) == 'a'
#      @test 1.37 < div(sym) < 1.38
#   end
#   @testset "data" begin
#     d=holds(the.file)
#     oo(d.cols.y[3])
#     oo(stats(d))
#     d1=holds(d,d.rows)
#     @test d1.cols.y[1].m2 == d.cols.y[1].m2
#   end
#   # @testset "sort" begin
#   #   d = holds(the.file)
#   #   println("b4    ",o(stats(d)))
#   #   a=sort(d.rows, lt= (x,y) -> better(d,x,y))
#   #   println("best  ", o(stats(holds(d,a[1:20]))))
#   #   println("rest  ", o(stats(holds(d,a[21:end]))))
#   # end
# end
#
true
