module ins_mem_decoder_top #(
    parameter INS_ADDR_WIDTH = 8,
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 32,
    parameter OPCODE_WIDTH = 3,
    parameter OP_SEL_WIDTH = 2,
    parameter INS_WIDTH = 64
) (
    input logic clk,     
    input logic rstn,
    input logic half_clk,
    output logic [ADDR_WIDTH-1:0] a_addr, b_addr,

    output logic [OP_SEL_WIDTH-1:0] pe_op,
    output logic [1:0] dot_ctrl,

    output logic [ADDR_WIDTH-1:0] r_addr,
    output logic write_en,
    output logic r_select 
);

    logic [INS_WIDTH-1:0] ins_mem_rdata;
    logic [INS_ADDR_WIDTH-1:0] pc;

    decoder #(
        .INS_ADDR_WIDTH(INS_ADDR_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .OPCODE_WIDTH(OPCODE_WIDTH),
        .OP_SEL_WIDTH(OP_SEL_WIDTH)
    ) decoder (
        .clk(clk),     
        .rstn(rstn),
        .half_clk(half_clk),
        .instruction(ins_mem_rdata[(OPCODE_WIDTH+ADDR_WIDTH*3)-1:0]),
        .pc(pc), 
        .a_addr(a_addr), 
        .b_addr(b_addr),
        .pe_op(pe_op),
        .dot_ctrl(dot_ctrl), 
        .r_addr(r_addr),
        .write_en(write_en), 
        .r_select(r_select) 
    );

    BRAM_INS ins_mem (
        .clka(clk),
        .ena(1'b1),
        .wea(1'b0),
        .addra({INS_ADDR_WIDTH{1'b0}}),
        .dina(64'b0),
        .clkb(clk),
        .enb(1'b1),
        .addrb(pc),
        .doutb(ins_mem_rdata)
    );


endmodule