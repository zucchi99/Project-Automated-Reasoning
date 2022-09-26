import math
import pandas as pd
import sys

cities = pd.read_csv('coordinates.csv', names = [ "region", "city", "latitude", "longitude"])

#print(cities)

original_stdout = sys.stdout # Save a reference to the original standard output

distances = []

for i, row_i in cities.iterrows():

    #cur_city = row_i[1]
    #distances.append([cur_city])
    distances.append([])

    for j, row_j in cities.iterrows():

        lat1 = row_i[2]
        lng1 = row_i[3]

        lat2 = row_j[2]
        lng2 = row_j[3]

        lat1Radians = lat1 * math.pi / 180
        lng1Radians = lng1 * math.pi / 180
        lat2Radians = lat2 * math.pi / 180
        lng2Radians = lng2 * math.pi / 180

        #raggio della terra in km
        r = 6376.5 

        x1 = r * math.cos(lat1Radians) * math.cos(lng1Radians)
        y1 = r * math.cos(lat1Radians) * math.sin(lng1Radians)
        z1 = r * math.sin(lat1Radians)
        x2 = r * math.cos(lat2Radians) * math.cos(lng2Radians)
        y2 = r * math.cos(lat2Radians) * math.sin(lng2Radians)
        z2 = r * math.sin(lat2Radians)

        distance = math.floor(math.sqrt((x2 - x1) ** 2 + (y2 - y1) ** 2 + (z2 - z1) ** 2))
        round_factor = 10 
        distance = (distance // round_factor) * round_factor
        
        distances[i].append(distance)

#columns = ['city'] + cities['city'].to_list()
#distances_pd = pd.DataFrame(distances, columns = columns)
distances_pd = pd.DataFrame(distances, columns = cities['city'].to_list())
#print(distances_pd)

lp_file  = 'distances.lp'
csv_file = 'distances.lp'

print(f'output files:{csv_file}, {lp_file}')

distances_pd.to_csv(csv_file, index=False)

with open(lp_file, 'w') as f:
    sys.stdout = f
    #num_of_cities = len(distances_pd)
    #print(num_of_cities)
    
    print(f'% distances matrix, obtained:')
    print(f'% python3 {sys.argv[0]}')
    print(f'% distance(X,Y,KM) :- universities_dom(X), universities_dom(Y), kilometers(KM).')
    print(f'distance(X,Y,KM) :- distance(Y,X,KM), universities_dom(X), universities_dom(Y).')
    for i, row_i in distances_pd.iterrows():
        j = i
        for j in range(i):
            km_i_j = row_i[j]
            #print(i, cities['city'][i], '\t', j, cities['city'][j], '\t', km_i_j, 'km')
            print(f'distance({i+1},{j+1},{km_i_j}).')
