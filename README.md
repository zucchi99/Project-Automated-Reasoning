# Project for Automated Reasoning Exam

In the repository I propose to solve the instance problem given in the <code>consegna.png</code> file.
It is required to implement the solution using both MiniZinc (known SAT-solver) and Answer Set Programming.

## Problem constraints

The problem requires to divide <code>total_money = 1mln</code> between various italian universities (U1, U2, ... , Un) and four different topics (T1, T2, T3, T4).

Each topic has a reserved share of <code>total_money</code>, for example <code>topics_perc = [40%, 30%, 10%, 20%]</code>.

Each topic is represented by <code>num_hubs = 1</code> hub and by <code>0 <= num_spokes <= 5</code> spokes.

Each university has a list of topics on which is interested (from 1 to 3).

Each university, for each topic, can be:
 * <code>hub</code>: receives <code>hubs_perc = 70%</code> of the topic share
 * <code>spoke</code>: receives an equal part <code>spoke_perc = 30%</code> of the topic share, to be divided with the other spokes
 * <code>non-participating</code>: do not receive anything
 
Clearly, non-interested universities will be non-participating, but the reverse is not true.

We define <code>d(x,y)</code> the distance in km between universities x and y.
Each university must gain a share quota between <code>min_money = 50k<code> <code>max_money = 150k</code>

The constraints are the following:
 * foreach U: U is hub for Ti ==> U is non-participating for all Tj, with j != i 
 * foreach U: U is spoke for Ti ==> d(U, hub(Ti)) <= 100 km
 * foreach U: U is spoke for Ti, Tj ==> U is non-participating for all Tk, with k != i and k != j
 * foreach U: min_money <= money_gained(U) <= max_money


## Obtain Distances

The coordinates of italian cities can be downloaded here:
https://github.com/MatteoHenryChinaski/Comuni-Italiani-2018-Sql-Json-excel
It is the file <code>distances/italy_geo.xlsx</code>.

In the python <code>distances/distances.py</code> I read the excel file and generate the matrixes accordingly to lp and mzn syntax.

## Generate Interested Table

In the python <code>interested/interested.py</code> I generate randomly the interests for each university, accordingly to lp and mzn matrixes syntax.

## Compilation

For the sake of simplicity for both Minizinc and ASP implementation the distances and interested matrixes are pasted directly in the source file.

### Minizinc 

Just open the <code>progetto.mzn</code> with MiniZinc and launch it from the IDE.
At the end of the file is possible to define various techniques to apply for the tree exploration.

### Answer Set Programming

ASP code can be launched from terminal, with the syntax:
<code>clingo [[-c own-param=value], ... ] [[--clingo-params=value], ...] source.lp</code>

The parameters needed are:
 * <code>tot</code>: total money to share
 * <code>min</code>: minimum money to gain for each university
 * <code>max</code>: maximum money to gain for each university
 * <code>n</code>: number of universities
 * <code>s</code>: number of topics

For example:
<code>clingo -c tot=1000 -c min=10 -c max=300 -c n=20 -c s=4 --time-limit=300 progetto.lp</code>

Note that is not recommended to work with big integers like tot=1MLN, the grounding process will be very slow.
I launched different instances always using tot=1000

## Performance Analysis
The performances of both MiniZinc and ASP have been stored manually to the <code>benchmarks.xlsx</code> file.

Some consideration on timings are present in the report <code>Relazione.pdf</code>.

## Check Correctness
The python <code>check_solution.py</code> can be used while developing to check the correctness of the solution.
