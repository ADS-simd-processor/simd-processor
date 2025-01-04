
import os
import sys

# instruction format
# opcode, A addr, B addr, R addr

UNIT = 4
OP_WIDTH = 3
ADDR_WIDTH = 10
ELEM_SIZE = 4 # 4 bytes

opcodes = {
    "nop" : 0b000,
    "add" : 0b001,
    "sub" : 0b010,
    "mul" : 0b011,
    "dot_sft" : 0b100,
    "dot_acc" : 0b101,
    "dot_clr" : 0b110,
    "pass_b" : 0b111
}

def dec2bin(x, width):
    return bin(x)[2:].zfill(width)

def single_inst_gen(op, a_addr, b_addr, r_addr):
    assembly = f"{op}\t{a_addr} {b_addr} {r_addr}"
    inst = dec2bin(a_addr, ADDR_WIDTH) + dec2bin(b_addr, ADDR_WIDTH) + dec2bin(r_addr, ADDR_WIDTH) + dec2bin(opcodes[op], OP_WIDTH)
    inst_val = int(inst, base=2)
    #print(assembly + "\t\t" + inst)
    asm_file.write(assembly + '\n')
    mem_file.write(dec2bin(inst_val, 64) + ',\n')

def inst_gen(op, a_start, b_start, r_start, m, n, p=0):

    n_times = max(n // UNIT, 1)

    if op == "add" or op == "sub":
        for i in range(m):
            for j in range(n_times):
                offset = n_times * i + j
                single_inst_gen(op, a_start + offset, b_start + offset, r_start + offset)

    elif op == "trans":
        for i in range(m):
            for j in range(n_times):
                offset = n_times * i + j
                single_inst_gen("pass_b", a_start + offset, b_start + offset, r_start + offset)

    elif op == "dot":
        # Row of A
        for i in range(m):
            # Col of B
            for k in range(p):
                offset = i * max(p // UNIT, 1) + (k // UNIT) 

                # Single element calculation
                if k % UNIT == 0:
                    single_inst_gen("dot_clr", a_start + n_times * i + 0, b_start + n_times * k + 0, r_start + offset)
                else:
                    single_inst_gen("dot_sft", a_start + n_times * i + 0, b_start + n_times * k + 0, r_start + offset)
                
                for j in range(1, n_times):
                    single_inst_gen("dot_acc", a_start + n_times * i + j, b_start + n_times * k + j, r_start + offset)

os.chdir(os.path.dirname(sys.argv[0]))

asm_file = open("assembly.txt", "w")
mem_file = open("instructions.txt", "w")

# inst_gen(op, a_start, b_start, r_start, m, n, p=0)
# op: add, sub, trans, dot
# a_start, b_start: starting addresses of matrices
# r_start: starting address to store result matrix
# m: rows of matrix A
# n: columns of matrix A
# p (only needed for dot product) columns of matrix B, to do dot product B has to be nxp matrix

# inst_gen("add", 0, 0, 0, 1, 4)
# inst_gen("sub", 1, 1, 1, 1, 8)
# inst_gen("dot", 3, 3, 4, 4, 8, 4)
inst_gen("add", 0, 0, 0, 2, 2)
inst_gen("sub", 2, 2, 2, 4, 4)
inst_gen("dot", 6, 6, 6, 16, 16, 16)
    
asm_file.close()
mem_file.close()