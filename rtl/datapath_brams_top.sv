`include "params.svh"

module datapath_brams_top #(
    parameter PE_COUNT = 4,
    parameter DATA_WIDTH = 32,
    parameter BRAM_DEPTH = 1024,
    parameter ADDR_WIDTH = $clog2(BRAM_DEPTH),
    parameter INS_ADDR_WIDTH = 8,
    parameter INS_WIDTH = 64
) (
    input logic clk, rstn,

    //BRAM A from PS
    input logic bram_a_wr_en,
    input logic [ADDR_WIDTH-1:0] bram_a_wr_addr,
    input logic [ADDR_WIDTH-1:0] bram_a_wr_data,

    //BRAM B from PS
    input logic bram_b_wr_en,
    input logic [ADDR_WIDTH-1:0] bram_b_wr_addr,
    input logic [ADDR_WIDTH-1:0] bram_b_wr_data,

    //BRAM INS from PS
    input logic bram_ins_wr_en,
    input logic [INS_ADDR_WIDTH-1:0] bram_ins_wr_addr,
    input logic [INS_ADDR_WIDTH-1:0] bram_ins_wr_data,

    //BRAM R from PS
    input logic [INS_ADDR_WIDTH-1:0] bram_r_r_addr,
    //BRAM R to PS
    output logic [INS_ADDR_WIDTH-1:0] bram_r_r_data

);

    logic [INS_WIDTH-1:0] ins_mem_rdata;
    logic [ADDR_WIDTH-1:0] a_addr, b_addr, r_addr; 
    logic write_en;     
    logic [INS_ADDR_WIDTH-1:0] pc;
    logic [PE_COUNT-1:0][DATA_WIDTH-1:0] a, b, store_out;

    datapath #(
        .PE_COUNT(PE_COUNT),
        .DATA_WIDTH(DATA_WIDTH),
        .BRAM_DEPTH(BRAM_DEPTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .INS_ADDR_WIDTH(INS_ADDR_WIDTH)
    )datapath_uut(
        .clk(clk), 
        .rstn(rstn),
        .instruction(ins_mem_rdata[(INS_WIDTH-1):((INS_WIDTH-1)-((OPCODE_WIDTH+ADDR_WIDTH*3)-1))]), 
        .a_addr(a_addr),
        .b_addr(b_addr), 
        .r_addr(r_addr), 
        .write_en(write_en),      
        .pc(pc) 
    );


    BRAM_A bram_a (
        .clka(clk),
        .ena(1'b1),
        .wea(wr_en_bram_a),
        .addra(bram_a_wr_addr),
        .dina(bram_a_wr_data),
        .clkb(clk),
        .enb(1'b1),
        .addrb(a_addr),
        .doutb(a)
    );

    BRAM_B bram_b (
        .clka(clk),
        .ena(1'b1),
        .wea(bram_b_wr_en),
        .addra(bram_b_wr_addr),
        .dina(bram_b_wr_data),
        .clkb(clk),
        .enb(1'b1),
        .addrb(b_addr),
        .doutb(b)
    );

    BRAM_R bram_r (
        .clka(clk),
        .ena(1'b1),
        .wea(write_en),
        .addra(r_addr),
        .dina(store_out),
        .clkb(clk),
        .enb(1'b1),
        .addrb(bram_r_r_addr),
        .doutb(bram_r_r_data)
    );

    BRAM_INS bram_ins (
        .clka(clk),
        .ena(1'b1),
        .wea(bram_ins_wr_en),
        .addra(bram_ins_wr_addr),
        .dina(bram_ins_wr_data),
        .clkb(clk),
        .enb(1'b1),
        .addrb(pc),
        .doutb(ins_mem_rdata)
    );

endmodule