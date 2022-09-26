% input parameters:
% u = [ u_1 ... u_n ]:   list of universities
% d = [ d_11 ... d_nn ]: matrix of distances between universities
% k = 4:                 number of sections
% p = [ p_1  ... p_k  ]: list of PNRR's share percentange per each section, sum(p_i) = 1
% i = [ i_11 ... i_nk ]: matrix of interest of each university (boolean values)
% H = 1:                 max number of hubs per section
% S = 5:                 max number of spokes per section
% T = 1.000.000:         PNRR money to share
% m =    50.000:         min money per each university
% M =   150.000:         max money per each university

% output:
% university hubs, spokes, affilitied of each sections

%NO!!!! Numeri troppo grandi, non riesce il grounding!!
%clingo -c tot=1000000 -c min=10000 -c max=300000 -c n=20 -c s=4 --time-limit=300 progetto.lp

%SI: meglio usare numeri più piccoli:
%clingo -c tot=1000 -c min=10 -c max=300 -c n=20 -c s=4 --time-limit=300 progetto.lp

% NB with tot=1mln, max{share}=40%, hubs_perc=70% ==> 1.000.000 * 0.4 * 0.7 = 280.000€ lower bound for max money!

% total money
total_money(tot).   
min_money(min). 
max_money(max). 

%list of universities
universities_dom(1..n).

%list of sections
sections_dom(1..s).

%shares per section
%partition 1
%section_perc(1, 40).
%section_perc(2, 30).
%section_perc(3, 10).
%section_perc(4, 20).
%partition 2
section_perc(1, 33).
section_perc(2, 27).
section_perc(3, 25).
section_perc(4, 15).

%percentage per hubs, spokes, affiliated
    hubs_perc(70).
non_hubs_perc(30).

%consistency check
:- min_money(min), total_money(tot), (n*min) > tot.
:- min_money(min), max_money(max), min > max.

%in case of COP: maximize(min(money_obtained))
%min_money_obtained(max_money(max)).
min_money_obtained(MY_MIN) :- MY_MIN = #min { MONEY : money_obtained(U,MONEY), universities_dom(U) }.
#maximize { MY_MIN : min_money_obtained(MY_MIN) }.

% exactly 1 hub per section
1 { hub(S, U) : universities_dom(U), not spoke(S, U), not affiliated(S, U), interested(S, U) } 1 :- sections_dom(S).

% maximum 5 spokes per section
0 { spoke(S, U) : universities_dom(U), not hub(S, U), not affiliated(S, U), interested(S, U) } 5 :- sections_dom(S).

% no limits on affiliated per section
0 { affiliated(S, U) : universities_dom(U), not spoke(S, U), not hub(S, U), interested(S, U) } n :- sections_dom(S).

% if university is hub then is not hub or spoke for another section
:- hub(S1, U),   hub(S2, U), S1 != S2.%, universities_dom(U), sections_dom(S1), sections_dom(S2).
:- hub(S1, U), spoke(S2, U), S1 != S2.%, universities_dom(U), sections_dom(S1), sections_dom(S2).

% a university can be spoke of maximum 2 sections
:- spoke(S1, U), spoke(S2, U), spoke(S3, U), S1 != S2, S1 != S3, S2 != S3.
    %,universities_dom(U), sections_dom(S1), sections_dom(S2), sections_dom(S3).

% distance < 100 between two universities
in_range(U1, U2) :- distance(U1, U2, KM), KM < 100.%, universities_dom(U1), universities_dom(U2).

% spokes must be distant at least 100 km
:- spoke(S, U1), spoke(S, U2), U1 != U2, in_range(U1, U2).
    %,universities_dom(U1), universities_dom(U2), sections_dom(S).

% if distance less than 100 km from hub or spoke then can be affiliated
can_be_affiliated(S, AFF) :-   hub(S, HUB), in_range(AFF, HUB).%, universities_dom(AFF), universities_dom(HUB), sections_dom(S).
can_be_affiliated(S, AFF) :- spoke(S, SPO), in_range(AFF, SPO).%, universities_dom(AFF), universities_dom(SPO), sections_dom(S).
:- not can_be_affiliated(S, AFF), affiliated(S, AFF).%, sections_dom(S), universities_dom(AFF).

%optimization:
%if university is no affiliated, is no hub, is no spoke for every section ==> not solution (no money gained)
participate(U) :- affiliated(S, U).%, sections_dom(S), universities_dom(U).
participate(U) :-      spoke(S, U).%, sections_dom(S), universities_dom(U).
participate(U) :-        hub(S, U).%, sections_dom(S), universities_dom(U).
:- not participate(U), universities_dom(U).

%money to divide per section
money_per_section( S, (T  * P / 100)) :- section_perc(S, P), total_money(T).%, sections_dom(S).
money_for_hubs(    S, (TS * P / 100)) :- money_per_section(S, TS), sections_dom(S),     hubs_perc(P).
money_for_non_hubs(S, (TS * P / 100)) :- money_per_section(S, TS), sections_dom(S), non_hubs_perc(P).

%number of spokes and affiliates per each section
%num_of_spokes(S, N)     :- N = #count { U :      spoke(S, U), sections_dom(S) }, sections_dom(S).
%num_of_affiliated(S, N) :- N = #count { U : affiliated(S, U), sections_dom(S) }, sections_dom(S).
%num_of_share_owners(S, SPO + AFF) :- num_of_spokes(S, SPO), num_of_affiliated(S, AFF), sections_dom(S).
num_of_share_owners(S, SPO + AFF) :- sections_dom(S),
    SPO = #count { U :      spoke(S, U) }, %, sections_dom(S), universities_dom(U) }, 
    AFF = #count { U : affiliated(S, U) }. %, sections_dom(S), universities_dom(U) }.
%no money waste! better here than after.. the sooner the better
:- num_of_share_owners(S, 0), sections_dom(S).

%share obtained by each non-hub university per section 
share_per_section(S, (TSNH / OWNERS)) :- money_for_non_hubs(S, TSNH), num_of_share_owners(S, OWNERS), OWNERS > 0, sections_dom(S).
%if no spokes and affiliates avoid division by zero... MONEY WASTE!
%share_per_section(S, 0) :- num_of_share_owners(S, OWNERS), OWNERS == 0.
%no money waste! same constraint as saying at least one affiliated or spoke per section!
%:- share_per_section(S, 0).

% money obtained by each university
gains_share(S, U, SHARE) :- share_per_section(S, SHARE), affiliated(S, U).%, sections_dom(S), universities_dom(U).
gains_share(S, U, SHARE) :- share_per_section(S, SHARE),      spoke(S, U).%, sections_dom(S), universities_dom(U).
gains_share(S, U, SHARE) :-    money_for_hubs(S, SHARE),        hub(S, U).%, sections_dom(S), universities_dom(U).
money_obtained(U, MONEY) :- universities_dom(U), MONEY = #sum { SHARE : gains_share(S, U, SHARE) }. %, universities_dom(U), sections_dom(S) }.

% guarantee some minimum money, forbid too much money
:- money_obtained(U,MONEY), min_money(MIN), MONEY < MIN.%, universities_dom(U).
:- money_obtained(U,MONEY), max_money(MAX), MONEY > MAX.%, universities_dom(U).

%python3 interested.py 4 2 4 0.9100653423283941
%Seed: 0.9100653423283941
%Sections: 4
%Min Interests: 2
%Max Interests: 4
interested(2,1).
interested(3,1).
interested(4,1).
interested(1,2).
interested(3,2).
interested(4,2).
interested(2,3).
interested(3,3).
interested(4,3).
interested(3,4).
interested(4,4).
interested(1,5).
interested(2,5).
interested(4,5).
interested(1,6).
interested(2,6).
interested(2,7).
interested(4,7).
interested(3,8).
interested(4,8).
interested(1,9).
interested(3,9).
interested(4,9).
interested(1,10).
interested(2,10).
interested(4,10).
interested(1,11).
interested(2,11).
interested(3,11).
interested(1,12).
interested(2,12).
interested(3,12).
interested(4,12).
interested(1,13).
interested(3,13).
interested(1,14).
interested(3,14).
interested(4,14).
interested(1,15).
interested(3,15).
interested(4,15).
interested(2,16).
interested(4,16).
interested(1,17).
interested(2,17).
interested(4,17).
interested(1,18).
interested(4,18).
interested(1,19).
interested(2,19).
interested(3,19).
interested(4,19).
interested(2,20).
interested(3,20).
interested(4,20).

% distances matrix, obtained:
% python3 distances.py >distances.lp
% distance(X,Y,KM) :- universities_dom(X), universities_dom(Y), kilometers(KM).
distance(X,Y,KM) :- distance(Y,X,KM), universities_dom(X), universities_dom(Y).
distance(2,1,40).
distance(3,1,30).
distance(3,2,50).
distance(4,1,80).
distance(4,2,100).
distance(4,3,50).
distance(5,1,190).
distance(5,2,210).
distance(5,3,160).
distance(5,4,110).
distance(6,1,290).
distance(6,2,310).
distance(6,3,260).
distance(6,4,210).
distance(6,5,120).
distance(7,1,240).
distance(7,2,250).
distance(7,3,210).
distance(7,4,160).
distance(7,5,100).
distance(7,6,60).
distance(8,1,220).
distance(8,2,230).
distance(8,3,190).
distance(8,4,140).
distance(8,5,130).
distance(8,6,110).
distance(8,7,40).
distance(9,1,240).
distance(9,2,240).
distance(9,3,210).
distance(9,4,160).
distance(9,5,150).
distance(9,6,120).
distance(9,7,60).
distance(9,8,20).
distance(10,1,200).
distance(10,2,200).
distance(10,3,160).
distance(10,4,110).
distance(10,5,110).
distance(10,6,120).
distance(10,7,60).
distance(10,8,20).
distance(10,9,40).
distance(11,1,180).
distance(11,2,190).
distance(11,3,150).
distance(11,4,100).
distance(11,5,80).
distance(11,6,110).
distance(11,7,50).
distance(11,8,50).
distance(11,9,70).
distance(11,10,30).
distance(12,1,180).
distance(12,2,180).
distance(12,3,150).
distance(12,4,110).
distance(12,5,150).
distance(12,6,170).
distance(12,7,100).
distance(12,8,60).
distance(12,9,60).
distance(12,10,40).
distance(12,11,60).
distance(13,1,140).
distance(13,2,130).
distance(13,3,110).
distance(13,4,80).
distance(13,5,160).
distance(13,6,200).
distance(13,7,140).
distance(13,8,100).
distance(13,9,110).
distance(13,10,80).
distance(13,11,90).
distance(13,12,40).
distance(14,1,170).
distance(14,2,140).
distance(14,3,150).
distance(14,4,150).
distance(14,5,250).
distance(14,6,280).
distance(14,7,220).
distance(14,8,170).
distance(14,9,180).
distance(14,10,160).
distance(14,11,180).
distance(14,12,120).
distance(14,13,90).
distance(15,1,220).
distance(15,2,180).
distance(15,3,200).
distance(15,4,200).
distance(15,5,290).
distance(15,6,320).
distance(15,7,260).
distance(15,8,210).
distance(15,9,200).
distance(15,10,200).
distance(15,11,220).
distance(15,12,150).
distance(15,13,130).
distance(15,14,50).
distance(16,1,100).
distance(16,2,80).
distance(16,3,80).
distance(16,4,80).
distance(16,5,190).
distance(16,6,260).
distance(16,7,200).
distance(16,8,160).
distance(16,9,170).
distance(16,10,140).
distance(16,11,140).
distance(16,12,100).
distance(16,13,60).
distance(16,14,70).
distance(16,15,120).
distance(17,1,100).
distance(17,2,60).
distance(17,3,110).
distance(17,4,130).
distance(17,5,250).
distance(17,6,330).
distance(17,7,270).
distance(17,8,230).
distance(17,9,240).
distance(17,10,200).
distance(17,11,210).
distance(17,12,170).
distance(17,13,130).
distance(17,14,90).
distance(17,15,120).
distance(17,16,60).
distance(18,1,130).
distance(18,2,80).
distance(18,3,140).
distance(18,4,170).
distance(18,5,290).
distance(18,6,360).
distance(18,7,300).
distance(18,8,260).
distance(18,9,270).
distance(18,10,240).
distance(18,11,250).
distance(18,12,210).
distance(18,13,160).
distance(18,14,110).
distance(18,15,140).
distance(18,16,100).
distance(18,17,30).
distance(19,1,220).
distance(19,2,180).
distance(19,3,230).
distance(19,4,260).
distance(19,5,380).
distance(19,6,440).
distance(19,7,380).
distance(19,8,330).
distance(19,9,340).
distance(19,10,320).
distance(19,11,330).
distance(19,12,270).
distance(19,13,240).
distance(19,14,160).
distance(19,15,150).
distance(19,16,180).
distance(19,17,120).
distance(19,18,90).
distance(20,1,220).
distance(20,2,190).
distance(20,3,240).
distance(20,4,280).
distance(20,5,400).
distance(20,6,480).
distance(20,7,410).
distance(20,8,370).
distance(20,9,380).
distance(20,10,350).
distance(20,11,360).
distance(20,12,310).
distance(20,13,270).
distance(20,14,210).
distance(20,15,200).
distance(20,16,210).
distance(20,17,140).
distance(20,18,110).
distance(20,19,60).

% show commands
#show hub/2.
#show spoke/2.
#show affiliated/2.

#show money_obtained/2.

%#show min_money_obtained/1.