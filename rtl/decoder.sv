`include "params.svh"

module decoder #(
    parameter INS_ADDR_WIDTH = 10,
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 32
) (
    input logic clk,     
    input logic rstn,
    input logic half_clk,
    
    input logic [(OPCODE_WIDTH+ADDR_WIDTH*3)-1:0] instruction, //From ins mem

    output logic [INS_ADDR_WIDTH-1:0] pc, //next_instruction address

    output logic [ADDR_WIDTH-1:0] a_addr, b_addr,

    output logic [OP_SEL_WIDTH-1:0] pe_op,
    output logic dot_prod_en, //enable dot product
    output logic shift, //1- shift, 0- accumulate

    output logic [ADDR_WIDTH-1:0] r_addr,
    output logic write_en, //BRAM write enable
    output logic r_select // 0 - Write PE output, 1- write dot product output
);

    logic [OPCODE_WIDTH-1:0] opcode;


    assign opcode = instruction[OPCODE_WIDTH-1 : 0];
    assign r_addr = instruction[OPCODE_WIDTH+ADDR_WIDTH-1 : OPCODE_WIDTH];
    assign b_addr = instruction[(OPCODE_WIDTH+ADDR_WIDTH*2)-1 : OPCODE_WIDTH+ADDR_WIDTH];
    assign a_addr = instruction[(OPCODE_WIDTH+ADDR_WIDTH*3)-1 : OPCODE_WIDTH+ADDR_WIDTH*2];


   always @(posedge clk) begin
        if (!rstn)
            pc <= 32'b0;
        else if (half_clk) begin
            pc <= pc + 1; 
        end
	end


    always_comb begin
        case (opcode)
            //Add A B R
            3'b000 : begin
                pe_op = 2'b01;
                write_en = 1;
                r_select = 0;
                dot_prod_en = 0;
                shift = 0;
            end
            //Sub A B R
            3'b001 : begin
                pe_op = 2'b10;
                write_en = 1;
                r_select = 0;
                dot_prod_en = 0;
                shift = 0;
            end
            // Mul A B R
            3'b010 : begin
                pe_op = 2'b11;
                write_en = 1;
                r_select = 0;
                dot_prod_en = 0;
                shift = 0;
            end
            // Dot product Shift A B R
            3'b011 : begin
                pe_op = 2'b11;
                write_en = 1;
                r_select = 1;
                dot_prod_en = 1;
                shift = 1;
            end  
            // Dot product Accumulate A B R
            3'b100 : begin
                pe_op = 2'b11;
                write_en = 0;
                r_select = 1;
                dot_prod_en = 1;
                shift = 0;
            end 
            // Pass B
            3'b101 : begin
                pe_op = 2'b00;
                write_en = 1;
                r_select = 0;
                dot_prod_en = 0;
                shift = 0;
            end           
            default : begin
                pe_op = 0;
                dot_prod_en = 0;
                write_en = 0;
                r_select = 0;
                shift = 0;
            end
        endcase
        
    end

endmodule