import numpy as np
import os
import sys

np.random.seed(13212)

UNITS = 4
BIT_WIDTH = 32
MASK = 0xFFFFFFFF

def dec2hex(x, width):
    #print(hex(x & MASK))
    x = np.uint32(x)
    
    return hex(x & MASK)[2:].zfill(width)

def write_data(file, matrix):
    #print(matrix)
    matrix = matrix.astype(np.int32)
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
b_file = open("b_data.txt", "w")

# write_data(file, matrix)
# can write several matrices like done below
# if using for dot product, b has to be given as transpose

# for add
a = np.random.randint(-50, 50, (2, 2), dtype=np.int32)
write_data(a_file, a)

b = np.random.randint(-50, 50, (2, 2), dtype=np.int32)
write_data(b_file, b)

print(f"a + b = {(a + b).astype(np.int32)}")

# for sub
a = np.random.randint(-30, 30, (4, 4), dtype=np.int32)
write_data(a_file, a)

b = np.random.randint(-30, 30, (4, 4), dtype=np.int32)
write_data(b_file, b)

print(f"a - b = {(a - b).astype(np.int32)}")

# for dot
a = np.random.randint(-10, 10, (16, 16), dtype=np.int32)
write_data(a_file, a)

b = np.random.randint(-10, 10, (16, 16), dtype=np.int32)
write_data(b_file, b)

print(f"a . b = {np.matmul(a, b.T).astype(np.int32)}")

a_file.close()
b_file.close()