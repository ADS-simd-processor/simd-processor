`include "params.svh"

module decoder #(
    ADDR_WIDTH = 10,
    DATA_WIDTH = 32
) (
    input logic [(OPCODE_WIDTH+ADDR_WIDTH*3+1)-1:0] instruction, //From ins mem

    output logic pc, //Program counter

    output logic [ADDR_WIDTH-1:0] a_addr, b_addr,

    output logic [OP_SEL_WIDTH-1:0] pe_op,
    output logic dot_prod_en, //enable dot product
    output logic shift, //1- shift, 0- accumulate

    output logic [ADDR_WIDTH-1:0] r_addr,
    output logic write_en, //BRAM write enable
    output logic r_select // 0 - Write PE output, 1- write dot product output
);

    logic [OPCODE_WIDTH-1:0] opcode;

    assign opcode = instruction[(OPCODE_WIDTH+ADDR_WIDTH*3+1)-1 -: OPCODE_WIDTH];
    assign a_addr = instruction[(ADDR_WIDTH*3+1)-1 -: ADDR_WIDTH];
    assign b_addr = instruction[(ADDR_WIDTH*2+1)-1 -: ADDR_WIDTH];
    assign r_addr = instruction[(ADDR_WIDTH+1)-1 -: ADDR_WIDTH];
    assign shift = instruction[0];

    always_comb begin
        case (opcode)
            //Add A B R
            3'b000 : begin
                pe_op = 2'b01;
                write_en = 1;
                r_select = 0;
                dot_prod_en = 0;
            end
            //Sub A B R
            3'b001 : begin
                pe_op = 2'b10;
                write_en = 1;
                r_select = 0;
                dot_prod_en = 0;
            end
            // Mul A B R
            3'b010 : begin
                pe_op = 2'b11;
                write_en = 1;
                r_select = 0;
                dot_prod_en = 0;
            end
            // Dot product A B R
            3'b011 : begin
                pe_op = 2'b11;
                write_en = 1;
                r_select = 1;
                dot_prod_en = 1;
            end  
            // Pass B
            3'b100 : begin
                pe_op = 2'b00;
                write_en = 1;
                r_select = 0;
                dot_prod_en = 0;
            end             
            default : begin
                pe_op = 0;
                dot_prod_en = 0;
                write_en = 0;
                r_select = 0;
            end
        endcase
        
    end

endmodule