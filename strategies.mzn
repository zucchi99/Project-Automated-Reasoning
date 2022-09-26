
%SINTAX:
solve 
    :: int_search(variables, varchoice, constrainchoice, strategy)
    :: restart_constant
    satisfy;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%VARIABLES
%array of var int

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%VARCHOICE
%Search variables in the given order
input_order

%Choose the variable with the largest number of attached constraints
occurrence

%Choose the variable with the smallest domain
first_fail

%Choose the variable with the largest domain
anti_first_fail

%Choose the variable with the smallest domain, breaking ties using the number of attached constraints
most_constrained

%Choose the variable with largest domain, divided by the number of attached constraints weighted by how often they have caused failure
dom_w_deg

%Choose the variable with the highest impact so far during the search
impact

%Choose the variable with largest difference between the two smallest values in its domain
max_regret

%Choose the variable with the smallest value in its domain
smallest

%Choose the variable with the largest value in its domain
largest 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CONTRAINCHOICE
%Assign values in ascending order
indomain 

%If the domain consists of several contiguous intervals, reduce the domain to the first interval. Otherwise bisect the domain.
indomain_interval 

%Assign the smallest/middle/largest value in the domain
indomain_min 
indomain_median 
indomain_max 

%Assign the value in the domain closest to the mean of its current bounds
indomain_middle 

%Assign a random value from the domain
indomain_random 

%Bisect the domain, excluding the lower half first
indomain_reverse_split 

%Bisect the domain, excluding the upper half first
indomain_split 

%Bisect the domain, randomly selecting which half to exclude first
indomain_split_random 

%Exclude smallest/middle/largest/random value from the domain
outdomain_min
outdomain_median
outdomain_max
outdomain_random

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%STRATEGY

%Completa, di default
complete

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%RESTART

%where n defines after how many nodes to restart
restart_constant(n)

%where n defines the number of nodes before the first restart. 
%The second restart gets 2n, the third 3n, and so on. Namely, the k th restart gets n*k nodes
restart_linear(n)

%the kth restart has a node limit of n*a^k
restart_geometric(a,n)

%the k th restart gets n*L[k]. L is the Luby sequence
%LUBY: 112112411211248 (Fibonacci più lento)
restart_luby(n)

%no restart
restart_none
