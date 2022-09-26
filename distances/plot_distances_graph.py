#!/usr/bin/python
import networkx as nx
import matplotlib.pyplot as plt
import pandas as pd
from sklearn.preprocessing import MinMaxScaler

adjacency_matrix = pd.read_csv('distances.csv')
coordinates_matrix = pd.read_csv('coordinates.csv', names = [ "region", "city", "latitude", "longitude"])
scaler = MinMaxScaler()
coordinates_scaled = (scaler.fit_transform(coordinates_matrix[["latitude", "longitude"]]) * 100).astype(int)
coordinates_scaled = pd.DataFrame(coordinates_scaled, columns = ["latitude", "longitude"])
#print(coordinates_scaled)

G = nx.Graph()

for i, row_i in adjacency_matrix.iterrows():
    city_i = adjacency_matrix.columns[i]
    coordinates_i = (coordinates_scaled['longitude'][i], coordinates_scaled['latitude'][i])
    G.add_node(i, pos=coordinates_i, city=city_i)
    #G.add_node(i, city=city_i)
    for j in range(len(row_i)):
        city_j = adjacency_matrix.columns[j]
        km_i_j = row_i[j]
        if(i < j and km_i_j < 100) :
            G.add_edge(i,j,distance=km_i_j)

print(G)
#print(G.nodes(data="city"))

pos=nx.get_node_attributes(G,'pos')
#pos=nx.spring_layout(G)
nx.draw(G,pos)
node_labels = nx.get_node_attributes(G, 'city') 
edge_labels = nx.get_edge_attributes(G, 'distance')
nx.draw_networkx_labels(G, pos, labels=node_labels)
nx.draw_networkx_edge_labels(G, pos, edge_labels=edge_labels)

plt.savefig('distances.png')
