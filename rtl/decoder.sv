`include "params.svh"

module decoder #(
    parameter INS_ADDR_WIDTH = 10,
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 32
) (
    input logic clk,     
    input logic rstn,
    input logic half_clk,
    input logic stall,
    input logic ins_valid,
    
    input logic [(OPCODE_WIDTH+ADDR_WIDTH*3)-1:0] instruction, //From ins mem

    output logic [INS_ADDR_WIDTH-1:0] pc, //next_instruction address

    output logic [ADDR_WIDTH-1:0] a_addr, b_addr,

    output logic [OP_SEL_WIDTH-1:0] pe_op,
    output logic [1:0] dot_ctrl, //00-disable, 01-shift, 10-accumulate,11-clear

    output logic [ADDR_WIDTH-1:0] r_addr,
    output logic write_en, //BRAM write enable
    output logic r_select, // 0 - Write PE output, 1- write dot product output

    output logic ins_done
);

    logic [OPCODE_WIDTH-1:0] opcode;

    assign opcode = instruction[OPCODE_WIDTH-1 : 0];
    assign r_addr = instruction[OPCODE_WIDTH+ADDR_WIDTH-1 : OPCODE_WIDTH];
    assign b_addr = instruction[(OPCODE_WIDTH+ADDR_WIDTH*2)-1 : OPCODE_WIDTH+ADDR_WIDTH];
    assign a_addr = instruction[(OPCODE_WIDTH+ADDR_WIDTH*3)-1 : OPCODE_WIDTH+ADDR_WIDTH*2];

    assign ins_done = ((opcode==3'b000) || (pc=={INS_ADDR_WIDTH{1'b1}}));

   always @(posedge clk) begin
        if (!rstn)
            pc <= {INS_ADDR_WIDTH{1'b0}};
        else if (half_clk) begin
            pc <= pc + 1; 
            if (pc=={INS_ADDR_WIDTH{1'b1}}) begin
                if (ins_valid) begin
                    pc <= {INS_ADDR_WIDTH{1'b0}};
                end else begin
                    pc <= pc;
                end
            end

        end
	end


    always_comb begin
        case (opcode)
            //Nop 
            3'b000 : begin
                pe_op = 2'b00;
                write_en = 0;
                r_select = 0;
                dot_ctrl = 2'b00;
            end
            //Add A B R
            3'b001 : begin
                pe_op = 2'b01;
                write_en = 1;
                r_select = 0;
                dot_ctrl = 2'b00;
            end
            //Sub A B R
            3'b010 : begin
                pe_op = 2'b10;
                write_en = 1;
                r_select = 0;
                dot_ctrl = 2'b00;
            end
            // Mul A B R
            3'b011 : begin
                pe_op = 2'b11;
                write_en = 1;
                r_select = 0;
                dot_ctrl = 2'b00;
            end
            // Dot product Shift A B R
            3'b100 : begin
                pe_op = 2'b11;
                write_en = 1;
                r_select = 1;
                dot_ctrl = 2'b01;
            end  
            // Dot product Accumulate A B R
            3'b101 : begin
                pe_op = 2'b11;
                write_en = 1;
                r_select = 1;
                dot_ctrl = 2'b10;
            end 
            // Dot product Clear
            3'b110 : begin
                pe_op = 2'b11;
                write_en = 1;
                r_select = 1;
                dot_ctrl = 2'b11;
            end 
            // Pass B
            3'b111 : begin
                pe_op = 2'b00;
                write_en = 1;
                r_select = 0;
                dot_ctrl = 2'b00;
            end           
            default : begin
                pe_op = 2'b00;
                write_en = 0;
                r_select = 0;
                dot_ctrl = 2'b00;
            end
        endcase
        
    end

endmodule