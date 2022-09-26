# 20 università
# da 1 a 3 interessi
# 4 tematiche

import random
import sys

sections = 4
min_interests = 2
max_interests = 4

if (len(sys.argv) >= 2 and sys.argv[1] == '--help') :
    print(f'usage: {sys.argv[0]} [ sections, min_interests, max_interests ], [ seed ]')
    print(f'example 1: {sys.argv[0]}')
    print(f'example 2: {sys.argv[0]} 4 2 4')
    print(f'example 3: {sys.argv[0]} 4 2 4 0.9100653423283941')
    sys.exit(0)

if (len(sys.argv) >= 4) :
    sections =      int(sys.argv[1])
    min_interests = int(sys.argv[2])
    max_interests = int(sys.argv[3])
    
if (len(sys.argv) >= 5) :
    seed = float(sys.argv[4])
else :
    random.seed(None)
    seed = random.random()

all_interests = [ [ False for _ in range(sections) ] for _ in range(20) ]

random.seed(seed)

for i in range(20) :
    interests = round(random.random() * (max_interests - min_interests)) + min_interests
    #print(random.random(), interests)
    j = 0
    while j < interests : 
        is_interested = int(random.random() * sections)
        if (all_interests[i][is_interested] == False) :
            all_interests[i][is_interested] = True
            j += 1

def print_parameters() :
    print(f'%python3 {sys.argv[0]} {sections} {min_interests} {max_interests} {seed}')
    print(f'%Seed: {seed}')
    print(f'%Sections: {sections}')
    print(f'%Min Interests: {min_interests}')
    print(f'%Max Interests: {max_interests}')

original_stdout = sys.stdout # Save a reference to the original standard output

# FOR ASP
file = f'interested_{sections}_{min_interests}_{max_interests}_{seed}.lp'
print('output file:', file)

with open(file, 'w') as f:
    sys.stdout = f
    print_parameters()
    for i in range(20) :
        for j in range(sections) :
            if (all_interests[i][j] == True):
                print(f'interested({j+1},{i+1}).')

# FOR MINIZINC
sys.stdout = original_stdout
file = f'interested_{sections}_{min_interests}_{max_interests}_{seed}.dzn'
print('output file:', file)

with open(file, 'w') as f:
    sys.stdout = f
    print_parameters()
    #print(all_interests)
    print('interested =')
    for i in range(20) :
        if i == 0 : print('[| ', end = '')
        else:       print(' | ', end = '')
        for j in range(sections) :
            print(str(all_interests[i][j]).lower(), ',\t', end = '')
        print()
    print('|];')