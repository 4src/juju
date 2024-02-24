<img src="https://img.shields.io/badge/tests-passing-green"> <img
src="https://img.shields.io/badge/julia-1.10.1-yellow"> <img
src="https://img.shields.io/badge/purpose-se--ai-blueviolet"> <img
src="https://img.shields.io/badge/platform-osx,linux-pink">

# Up.jl : simple incremental sequential optimization

Life is short and there is too much to see.
So how do we make intelligent decisions,
in the face of limited knowledge?

To say that another way, we are trying to learn a model
$f$ such that we can predict $y=f(x)$ where $y$ are goals
and $x$ are the model inputs.  In many real-world scenarios,
we can find lots of $x$ candidates, but it it is too expensive or
slow to find all their associated $y$ values. So we need to learn
$f$ using lots of $x$ and only a few $y$ labels.

Sequential model optimizers (SMO) label a few examples,  then take
a guess at what $f$ might be. This guess is then quickly
applied to lots of  $x$ values to find guesses for their $y$ labels.  The item with most interesting guess is then labelled,
$f$ is updated, and the cycle repeats.

Often, SMO builds its models using complex algorithms
(e.g. Gaussian process models [^google]). This code is an
experiment if a much simpler approach works (based on a N&auml;ive
Bayes classifier).

## Multi-Objective Optimization
To support multi-objective optimization, this code sorts items by
`distance to heaven`; i.e. the Euclidean distance of all the
$f$ values to  `heaven` (the ideal values for each goal).

```julia <up d2h>
function d2h(data::Data, v::Vector) 
  d,n  = 0,0
  for (n,col) in data.cols.y 
    d += (col.heaven - norm(col, v[col.at])) ^ 2 
    n += 1 end 
  (d/n) ^ .5 end
```

## Data Model
For that to work, when we read in a csv data file, we need to fill in some  details  e.g. (a) what are the $y$ values (used in `data.cols.y`) and (b) what is heaven for each $y$ goal (used in `col.heaven`). To make that work, the column names (on line one
of the csv file) have some special symbols:

- Anything starting with an upper-case letter (like `Age`) is a `Num`eric;
- Anything ending with `+`,`-` is a $y$ goal to be maximized
  or minimized (respectively);
- `Heaven` for maximal goals  is 1 (and for minimal goals, `heaven` is 0).

```julia <up col>
COL(s=" ",n=0) = (occursin(r"^[A-Z]", s) ? NUM : SYM)(s,n) 
SYM(s=" ",n=0) = Sym(at=n, txt=s, has=Dict(_)) 
NUM(s=" ",n=0) = Num(at=n, txt=s, heaven= s[end]=="-" ? 0 : 1)
```
In the above `s`and `n` are the name of the column and its column number.
`Num`s and `Sym`s handle numeric and symbolic columns, respectively. 

```julia <up numsym>
@kwdef mutable struct Num
  at=0; txt=""; n=0; mu=0; m2=0; sd=0; lo=1E-30; hi= -1E-30; heaven=1 end

@kwdef mutable struct Sym
  at=0; txt=""; n=0; has=Dict() end
```
Inside `Sym`, `has` stores the frequency counts of symbols in a column.
And inside `Num`, we calculate `sd` incrementally using `n`,`mu` and the
second moment variable `m2` (via the Welford algorithn  [^welford]).

```julia <up add!>
function add!(sym::Sym, x) sym.n+=1; sym.has[x]=1+get(sym.has,x,0) end 
function add!(num::Num, x::Number) 
  num.n  += 1
  d       = x - num.mu
  num.mu += d / num.n
  num.m2 += d * (x -  num.mu)
  num.sd  =  num.n > 1 ? (num.m2 / (num.n - 1))^.5 : 0
  num.lo  = min(x, num.lo)
  num.hi  = max(x, num.hi) end
```

```julia <up options>
options="
up.jl: smos
(c)2024 Tim Menzies <timm@ieee.org>, BSD-2 license

OPTIONS:
  -b --bins   initial number of bins   = 16
  -C --Cohen  too small                = .35
  -f --file   csv data file            =  data/auto93.csv
  -F --Far    how far to look          = .95
  -h --help   show help                = false
  -H --Half   where to find for far    = 256
  -m --min    min size                 = .5
  -p --p      distance coefficient     = 2
  -r --reuse  do npt reuse parent node = true
  -s --seed   random number seed       = 937162211"
```

After that, the code:

<img align=right width=600 src="https://miro.medium.com/v2/resize:fit:846/1*und5wL5DogTb8zkyOaFmrA.png">

- Divide the `N` items into `todo` and `done`
  - where `done` is very small (say, 4)
  - and `todo` is all the rest.
- Label all the goals for eveything in `todo`.
- For a limited number of times do:
  - Sort `done` into `best` and `rest` (using `distance to heaven`);
  - Build a model that can recognize `best` and `rest`
    - Here we are use a simple Naive Bayes classifier.
  - For everything in `todo`,find the item that has
    - max likelihood of being in `best`;
    - and min likelihood of being in `rest`.
  - Move that item from `todo` to `done`, and label all its goals.

Return the best item in `best`.

This  code uses  two conventions:  

- This code uses a global `the` variable to store config information,
  extracted from the above `options` string.
- `xxx = XXX()` uses the `XXX()` constructor to create a variable of type `Xxx`.
  - e.g.  `sym = SYM()` creates `sym`, a variable of type `Sym`.

[^google]: Golovin, D., Solnik, B., Moitra, S., Kochanski, G., Karro, J., & Sculley, D. (2017, August). Google vizier: A service for black-box optimization. In Proceedings of the 23rd ACM SIGKDD international conference on knowledge discovery and data mining (pp. 1487-1495).

[^welford]: https://en.wikipedia.org/wiki/Algorithms_for_calculating_variance#Welford's_online_algorithm

