import math
import pandas as pd
import sys

distance_matrix = pd.read_csv('distances/distances.csv').values.tolist()

solution_matrix = [

    [0,1,2,2],
    [2,0,1,0],
    [0,2,1,1],
    [0,0,0,3],
    [2,2,0,0],
    [3,0,0,0],
    [0,3,0,0],
    [0,0,3,0],
    [0,0,0,0],
    [0,0,0,0],
    [0,0,0,0],
    [0,0,0,0],
    [0,0,0,0],
    [0,0,0,0],
    [0,0,0,0],
    [0,0,0,0],
    [0,0,0,0],
    [0,0,0,0],
    [0,0,0,0],
    [0,0,0,0]

]

hubs = [ -1 for _ in range(len(solution_matrix[0])) ]
spokes = [ [] for  _ in range(len(solution_matrix[0])) ]

#find hubs
for i in range(len(solution_matrix)) :
    row = solution_matrix[i]
    for j in range(len(row)):
        if (row[j] == 3) :
            if hubs[j] >= 0 :
                print("error too many hubs:",i+1,hubs[j]+1)
                sys.exit(1)
            else :
                hubs[j] = i
        elif (row[j] == 2) :
            spokes[j].append(i)

#check distances from hubs and spokes
for i in range(len(solution_matrix)) :
    row = solution_matrix[i]
    for j in range(len(row)):
        #affiliated distance < 100 km from a hub or a spoke
        if(row[j] == 1) :
            d = distance_matrix[i][hubs[j]]
            if (d >= 100) :
                #if distant from hub check spokes
                k=0
                ok=False
                while((not ok) and k < len(spokes[j])) :
                    ok = distance_matrix[i][spokes[j][k]] < 100
                if(not ok) :
                    print("error: affiliated far from hubs and spokes:", i+1, d, j)
                    sys.exit(2)

#check distances between spokes
for j in range(len(spokes)) :
    for i1 in range(len(spokes[j])) :
        for i2 in range(i1+1, len(spokes[j])) :
            d = distance_matrix[spokes[j][i1]][spokes[j][i2]]
            if (d < 100) :
                print("error: spokes near each other:", i1, i2, j)
                sys.exit(3)

print("everything ok")