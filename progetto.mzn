include "globals.mzn";

%minizinc --solver Gecode progetto.mzn --output-time --solver-time-limit 300000 -D n=20 -D min_money=10 -D tot_money=100000 -D max_money=30000

%for biggers s,n is necessary to generate new table of interests and distances
int: s =  4; %number of sections   used (s <=  4)
int: n; %number of university used (n <= 20)

% total budget available, minimum and maximum limits on money gained by each university
% use tot_money < 100.000-500.000 !!!!
int: tot_money;
int: min_money;
int: max_money;

%percentage of money received by each section
array [1..4] of int: sections_perc;
 sections_perc = [ 33, 27, 25, 15 ];
%sections_perc = [ 40, 30, 10, 20 ];

%percentage of money received by hub and non_hubs participants
int:     hubs_perc = 70; % 70%
int: non_hubs_perc = 30; % 30%

% participation codification
int: nothing    = 0;
int: affiliated = 1;
int: spoke      = 2;
int: hub        = 3;

% matrix of participation for each couple (university, section)
array[1..n, 1..s] of var 0..3: role;
%role[i,j] == 0 <==> role[i] is not involved in section j
%role[i,j] == 1 <==> role[i] is affiliated  for section j
%role[i,j] == 2 <==> role[i] is spoke       for section j
%role[i,j] == 3 <==> university[i] is hub         for section j

%matrix of distances between universities
array [1..20, 1..20] of int: distance;

%matrix of section interests for all universities
array [1..20, 1..4] of bool: interested;

%number of non_hubs participants in a section
array [1..s] of var int: num_of_share_owners;

%money offered from every section to hubs and non_hubs
array [1..s] of var int:     money_for_hubs;
array [1..s] of var int: share_per_section;

%total money obtained by every university
array [1..n] of var int: money_obtained;

%list of university names, only for output purposes
array [1..20] of string: city_name;
city_name =   [ 
  "Bologna", "Ferrara", "Modena", "Parma", "Genova", "Torino", "Vercelli", 
  "Castellanza", "Varese", "Milano", "Pavia", "Bergamo", "Brescia", 
  "Trento", "Bolzano", "Verona", "Padova", "Venezia", "Udine", "Trieste"
];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%consistency check
constraint min_money * n <= tot_money;
constraint min_money     <= max_money;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%if not interested stay out
constraint forall(i in 1..n, j in 1..s) (
  role[i,j] == nothing \/ interested[i,j]
);

%exactly one hub per section
constraint forall(j in 1..s) (
  count (role[1..n,j], hub) == 1
);

%maximum 5 spokes per section
constraint forall(j in 1..s) (
  count (role[1..n,j], spoke) <= 5
);

%minimum one affiliated or spoke per section (no money waste)
constraint forall(j in 1..s) (
  (count (role[1..n,j], affiliated) + count (role[1..n,j], spoke)) > 0
);

%university is hub ==> in all others sections is nothing or affiliated
constraint forall(i in 1..n, j1,j2 in 1..s 
  where role[i,j1] == hub /\ j1 != j2)(
    role[i,j2] <= affiliated
);

%university is spoke ==> can be spoke in just one more
constraint forall(i in 1..n, j1,j2,j3 in 1..s 
  where j1 != j2 /\ j1 != j3 /\ j2 != j3)(
    not (role[i,j1] >= spoke /\ role[i,j2] >= spoke /\ role[i,j3] >= spoke)
);

%spokes must be distant at least 100 km
constraint forall(i1,i2 in 1..n, j in 1..s 
  where i1 != i2 /\ role[i1,j] == spoke /\ role[i2,j] == spoke)(
    distance[i1,i2] >= 100
);

% if distance less than 100 km from hub or spoke then can be affiliated
constraint forall(i in 1..n, j in 1..s
  where role[i,j] == affiliated)(
    exists(i1 in 1..n
      where role[i1,j] >= spoke)(
        distance[i,i1] < 100
));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%optimization zone
%most of times trivial constraints, but helpful in cutting bad possible solutions

%everybody receives something ==> minimum money to receive = tot_money * min{sections_perc} * 1/n
%NB with the more strict minimum money constraint this constraint is trivial, but MAYBE helpful for cutting bad solutions
%idea: instead of always calculate money obtained, if uni never participate ==> income = 0 ==> refuse solution
%in fact:
% sections_perc=[33%, 27%, 25%, 15%]	seed=0.36905256665584900, max:300,000€
% min:20,000€ ==> with: 57 secs, without: 180 secs
% min:21,000€ ==> with:  2 secs, without:  50 secs
constraint forall(i in 1..n) (
  sum(role[i,1..s]) > 0
);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%money zone

%share owners of a section s = spokes and affiliated of s
constraint forall(j in 1..s)( 
  num_of_share_owners[j] == 
    (count(role[1..n,j], spoke) + count(role[1..n,j], affiliated))
);

%share per section s = money gained by each hub from section s
constraint forall(j in 1..s)(
      money_for_hubs[j] == calc_money_per_section(tot_money, 1, sections_perc[j], hubs_perc)
);

%share per section s = money gained by each spoke/affiliated from section s
constraint forall(j in 1..s)(
  share_per_section[j] == calc_money_per_section(tot_money, num_of_share_owners[j], sections_perc[j], non_hubs_perc)
);

%money obtained by each university
constraint forall(i in 1..n)( 
  money_obtained[i] == 
    %hub revenue
    sum([ if j >= 0
            then money_for_hubs[j]
            else 0 endif 
            | j in indexes_of(hub, role[i,1..s]) 
        ])
    +
    %spoke revenues
    sum([ if j >= 0
            then share_per_section[j]
            else 0 endif 
            | j in indexes_of(spoke, role[i,1..s]) 
        ])
    +
    %affiliated revenues
    sum([ if j >= 0
            then share_per_section[j]
            else 0 endif 
            | j in indexes_of(affiliated, role[i,1..s]) 
        ])
);

%money distribution constraints
constraint forall(i in 1..n)(
  money_obtained[i] >= min_money /\
  money_obtained[i] <= max_money
);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%functions zone

%returns [j_1, ..., j_n] t.c. if array[i] == val: j_i == i, else j_i = -1
function array[int] of var int: indexes_of(int: val, array[int] of var int: my_array) = 
       [ if val == my_array[i] then i else -1 endif | i in index_set(my_array) ];
       
%calculate the money share for a single section
%NB1: if hub pass num_of_share_owners=1
%NB2: the formula with less error is the second one. This implies that due to the bigger error on the first some problems are actually solvable ma the output is UNSAT.
%To avoid this use as much as possible small numbers (tot_money <= 100.000).
%Example (obviously both are actually SAT (same solution money*10) but the second actually is not (flooring error propagation)
%   SAT: n=8, s=4, tot_money=  100.000, min_money= 7.400, max_money= 30.000
% UNSAT: n=8, s=4, tot_money=1.000.000, min_money=74.000, max_money=300.000
function var int: calc_money_per_section(int: tot_money, var int: num_of_share_owners, int: sections_perc, int: participation_perc) =
       if tot_money >= 500000
         %big   numbers: try to avoid overflow       ==> before divide then multiply
         then (tot_money div (100 * 100 * num_of_share_owners) * sections_perc * participation_perc)
         %small numbers: reduce approximation errors ==> before multiply then divide
         else (tot_money * sections_perc * participation_perc div (100 * 100 * num_of_share_owners)) 
       endif;

function var int: mean(array[int] of var int: my_array) = 
  sum(my_array) div length(my_array);
  
function var float: float_mean(array[int] of var int: my_array) = 
  sum(my_array) / length(my_array);

function var float: standard_deviation(var float: mean, array[int] of var int: my_array) = 
  sqrt(sum([ pow(my_array[i]-mean, 2) | i in index_set(my_array) ]) / (length(my_array)-1));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%data zone

% distances matrix, obtained:
% basic (omitted) regex from the distances.csv file
distance = 
[| 0,40,30,80,190,290,240,220,240,200,180,180,140,170,220,100,100,130,220,220
 | 40,0,50,100,210,310,250,230,240,200,190,180,130,140,180,80,60,80,180,190
 | 30,50,0,50,160,260,210,190,210,160,150,150,110,150,200,80,110,140,230,240
 | 80,100,50,0,110,210,160,140,160,110,100,110,80,150,200,80,130,170,260,280
 | 190,210,160,110,0,120,100,130,150,110,80,150,160,250,290,190,250,290,380,400
 | 290,310,260,210,120,0,60,110,120,120,110,170,200,280,320,260,330,360,440,480
 | 240,250,210,160,100,60,0,40,60,60,50,100,140,220,260,200,270,300,380,410
 | 220,230,190,140,130,110,40,0,20,20,50,60,100,170,210,160,230,260,330,370
 | 240,240,210,160,150,120,60,20,0,40,70,60,110,180,200,170,240,270,340,380
 | 200,200,160,110,110,120,60,20,40,0,30,40,80,160,200,140,200,240,320,350
 | 180,190,150,100,80,110,50,50,70,30,0,60,90,180,220,140,210,250,330,360
 | 180,180,150,110,150,170,100,60,60,40,60,0,40,120,150,100,170,210,270,310
 | 140,130,110,80,160,200,140,100,110,80,90,40,0,90,130,60,130,160,240,270
 | 170,140,150,150,250,280,220,170,180,160,180,120,90,0,50,70,90,110,160,210
 | 220,180,200,200,290,320,260,210,200,200,220,150,130,50,0,120,120,140,150,200
 | 100,80,80,80,190,260,200,160,170,140,140,100,60,70,120,0,60,100,180,210
 | 100,60,110,130,250,330,270,230,240,200,210,170,130,90,120,60,0,30,120,140
 | 130,80,140,170,290,360,300,260,270,240,250,210,160,110,140,100,30,0,90,110
 | 220,180,230,260,380,440,380,330,340,320,330,270,240,160,150,180,120,90,0,60
 | 220,190,240,280,400,480,410,370,380,350,360,310,270,210,200,210,140,110,60,0
 |];
 

%python3 interested.py 4 2 4 0.9100653423283941
%Seed: 0.9100653423283941
%Sections: 4
%Min Interests: 2
%Max Interests: 4
interested =
[| false ,	true ,	true ,	true ,	
 | true ,	false ,	true ,	true ,	
 | false ,	true ,	true ,	true ,	
 | false ,	false ,	true ,	true ,	
 | true ,	true ,	false ,	true ,	
 | true ,	true ,	false ,	false ,	
 | false ,	true ,	false ,	true ,	
 | false ,	false ,	true ,	true ,	
 | true ,	false ,	true ,	true ,	
 | true ,	true ,	false ,	true ,	
 | true ,	true ,	true ,	false ,	
 | true ,	true ,	true ,	true ,	
 | true ,	false ,	true ,	false ,	
 | true ,	false ,	true ,	true ,	
 | true ,	false ,	true ,	true ,	
 | false ,	true ,	false ,	true ,	
 | true ,	true ,	false ,	true ,	
 | true ,	false ,	false ,	true ,	
 | true ,	true ,	true ,	true ,	
 | false ,	true ,	true ,	true ,	
|];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%execution zone

%problem with big numbers
%constraint standard_deviation((tot_money div n), money_obtained) < 100000;

%solve satisfy;

solve 
  %   :: int_search(role, first_fail, indomain_random)
  %   :: int_search(role, first_fail, indomain_min)
  %   :: restart_luby(63)
  %   :: restart_geometric(1.5, 100)
  %   satisfy;
      maximize(min(money_obtained));
  %   minimize(max(money_obtained)); %nosense, max is almost always tot_money * 70% * max{section_perc}
  %   minimize(max(money_obtained)-min(money_obtained)); %nosense, max is almost always tot_money * 70% * max{section_perc}
  %   minimize(standard_deviation((tot_money div n), money_obtained));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

output
[
  if col == 1 then show(city_name[row]) ++ "    \t" else "" endif ++
  show(role[row, col]) ++ 
  if col == s then "\n" else " " endif 
  | row in 1..n, col in 1..s
]
++
[ "\n" ]
++
[
  show(city_name[row]) ++ "     \t" ++
  show(money_obtained[row]) ++ "\n" | row in 1..n
]
++
[ "\nmean: " ++ show(float_mean(money_obtained)) ++ "\n"]
++
[ "std:  " ++ show(standard_deviation(float_mean(money_obtained), money_obtained)) ++ "\n"]
++
[ "\nnon hubs money: " ++ show(share_per_section) ++ "\n" ]
++
[ "    hubs money: " ++ show(money_for_hubs) ++ "\n" ]
++
[ "num of share owners: " ++ show(num_of_share_owners) ++ "\n\n" ]
++
[ "params: total: " ++ show(tot_money) ++ "\n" ]
++
[ "params: min: " ++ show(min_money) ++ " max: " ++ show(max_money) ++ "\n" ]
++
[ "reals:  min: " ++ show(min(money_obtained)) ++ " max: " ++ show(max(money_obtained)) ++ "\n" ]
;