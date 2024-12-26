import numpy as np
import os
import sys

np.random.seed(13212)

UNITS = 4
BIT_WIDTH = 32

def dec2hex(x, width):
    return hex(x)[2:].zfill(width)

def write_data(file, matrix):
    
    r, c = matrix.shape

    for i in range(r):
        for j in range(0, c, UNITS):
            row = ""
            for k in range(j, min(c, j + UNITS)):
                row = dec2hex(matrix[i][k], BIT_WIDTH // 4) + row
            if len(row) < UNITS * BIT_WIDTH // 4:
                row = row.zfill(UNITS * BIT_WIDTH // 4)

            file.write(row + ",\n")

os.chdir(os.path.dirname(sys.argv[0]))
a_file = open("a_data.txt", "w")
b_file = open("a_data.txt", "w")

a = np.random.randint(0, 1000, (2, 8))
print(a)

write_data(a_file, a)

a_file.close()
b_file.close()