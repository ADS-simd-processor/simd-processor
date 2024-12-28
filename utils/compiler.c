#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#define UNIT 4
#define OP_WIDTH 3
#define ADDR_WIDTH 10
#define INST_WIDTH 64
#define MAX_INST_COUNT 65536

#define SHIFT_A ADDR_WIDTH*2 + OP_WIDTH
#define SHIFT_B ADDR_WIDTH + OP_WIDTH
#define SHIFT_R OP_WIDTH

#define MAX(a, b) ((a) > (b) ? (a) : (b))

typedef enum {
    NOP,
    ADD,
    SUB,
    MUL,
    DOT_SFT,
    DOT_ACC,
    DOT_CLR,
    PASS_B
} Opcode;

typedef enum {
    MADD,
    MSUB,
    MTRANS,
    MDOT
} MatrixOp;

uint64_t instructions[MAX_INST_COUNT];
uint16_t pc = 0;

void single_inst_gen(Opcode opcode, uint16_t a_addr, uint16_t b_addr, uint16_t r_addr) {
    instructions[pc++] = ((uint64_t)a_addr << SHIFT_A) | ((uint32_t)b_addr << SHIFT_B) | ((uint32_t)r_addr << SHIFT_R) | opcode;
}

void inst_gen(MatrixOp op, uint16_t a_start, uint16_t b_start, uint16_t r_start, uint16_t m, uint16_t n, uint16_t p) {

    uint16_t n_times = MAX(n / UNIT, 1);

    Opcode opcode;
    uint16_t i, j, k, offset;
    
    if (op != MDOT) {
        if (op == MADD) opcode = ADD;
        else if (op == MSUB) opcode = SUB;
        else if (op == MTRANS) opcode = PASS_B;
        else opcode = NOP;

        for (i = 0; i < m; i++) {
            for (j = 0; j < n_times; j++) {
                offset = n_times * i + j;
                single_inst_gen(opcode, a_start + offset, b_start + offset, r_start + offset);
            }
        }

    } else {
        // Row of A
        for (i = 0; i < m; i++) {
            // Col of B
            for (k = 0; k < p; k++) {
                offset = i * MAX(p / UNIT, 1) + (k / UNIT);

                // Single element calculation
                if (k % UNIT == 0) {
                    single_inst_gen(DOT_CLR, a_start + n_times * i + 0, b_start + n_times * k + 0, r_start + offset);
                } else {
                    single_inst_gen(DOT_SFT, a_start + n_times * i + 0, b_start + n_times * k + 0, r_start + offset);
                }

                for (j = 1; j < n_times; j++) {
                    single_inst_gen(DOT_ACC, a_start + n_times * i + j, b_start + n_times * k + j, r_start + offset);
                }   
            }
        }
    }
}

void reset_pc() {
    pc = 0;
}

void write_to_file(const char *filepath) {

    FILE *file = fopen(filepath, "w");
    if (file == NULL)
    {
        printf("Failed to open file for writing.\n");
        return;
    }

    for (int i = 0; i <= (uint16_t)(pc - 1); i++)
    {
        for (int j = INST_WIDTH-1; j >= 0; j--)
            fprintf(file, "%d", (instructions[i] >> j) & 1);

        fprintf(file, ",\n");
    }

    fclose(file);
}

int main() {

    inst_gen(MADD, 0, 0, 0, 1, 4, 0);
    inst_gen(MSUB, 1, 1, 1, 1, 8, 0);
    inst_gen(MTRANS, 0, 0, 3, 1, 4, 0);
    inst_gen(MDOT, 3, 3, 4, 4, 8, 4);

    write_to_file("instructions_c.txt");
}


