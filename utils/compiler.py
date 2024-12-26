

# instruction format
# opcode, A addr, B addr, R addr

UNIT = 4
OP_WIDTH = 3
ADDR_WIDTH = 10
ELEM_SIZE = 4 # 4 bytes

opcodes = {
    "add" : 0b000,
    "sub" : 0b001,
    "mul" : 0b010,
    "dot_sft" : 0b011,
    "dot_acc" : 0b100,
    "pass_b" : 0b101
}

def dec2bin(x, width):
    return bin(x)[2:].zfill(width)

def single_inst_gen(op, a_addr, b_addr, r_addr):
    assembly = f"{op}\t{a_addr} {b_addr} {r_addr}"
    inst = dec2bin(a_addr, ADDR_WIDTH) + dec2bin(b_addr, ADDR_WIDTH) + dec2bin(r_addr, ADDR_WIDTH) + dec2bin(opcodes[op], OP_WIDTH)
    print(assembly + "\t\t" + inst)
    file.write(assembly + '\n')

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
                single_inst_gen("dot_sft", a_start + n_times * i + 0, b_start + n_times * k + 0, r_start + offset)
                
                for j in range(1, n_times):
                    single_inst_gen("dot_acc", a_start + n_times * i + j, b_start + n_times * k + j, r_start + offset)

file = open("assembly.txt", "w")

inst_gen("dot", 0, 0, 0, 16, 16, 16)
    
file.close()