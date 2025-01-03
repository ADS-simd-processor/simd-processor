`include "params.svh"

module datapath_top #(
    parameter PE_COUNT = 8,
    parameter DATA_WIDTH = 32,
    parameter BRAM_DEPTH = 1024,
    parameter ADDR_WIDTH = $clog2(BRAM_DEPTH),
    parameter INS_ADDR_WIDTH = 11,
    parameter INS_WIDTH = 64
) (
    input logic clk, rstn,
    input logic stall,
    input logic in_data_valid,

    //BRAM A from PS
    input logic bram_a_wr_en,
    input logic [ADDR_WIDTH-1:0] bram_a_wr_addr,
    input logic [PE_COUNT-1:0][DATA_WIDTH-1:0] bram_a_wr_data,

    //BRAM B from PS
    input logic bram_b_wr_en,
    input logic [ADDR_WIDTH-1:0] bram_b_wr_addr,
    input logic [PE_COUNT-1:0][DATA_WIDTH-1:0] bram_b_wr_data,

    //BRAM INS from PS
    input logic bram_ins_wr_en,
    input logic [INS_ADDR_WIDTH-1:0] bram_ins_wr_addr,
    input logic [INS_WIDTH-1:0] bram_ins_wr_data,

    //BRAM R from PS
    input logic [INS_ADDR_WIDTH-1:0] bram_r_r_addr,
    //BRAM R to PS
    output logic [PE_COUNT-1:0][DATA_WIDTH-1:0] bram_r_r_data,

    output logic out_data_valid
);

    logic [INS_WIDTH-1:0] bram_ins_din;
    logic [ADDR_WIDTH-1:0] bram_a_addr, bram_b_addr, bram_r_addr; 
    logic bram_r_wen;     
    logic [INS_ADDR_WIDTH-1:0] pc;
    logic [PE_COUNT-1:0][DATA_WIDTH-1:0] bram_a_dout, bram_b_dout, bram_r_din;

    datapath #(
        .PE_COUNT(PE_COUNT),
        .DATA_WIDTH(DATA_WIDTH),
        .BRAM_DEPTH(BRAM_DEPTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .INS_ADDR_WIDTH(INS_ADDR_WIDTH)
    ) datapath_uut (.*);

    BRAM_A bram_a (
        .clka(clk),
        .ena(1'b1),
        .wea(bram_a_wr_en),
        .addra(bram_a_wr_addr),
        .dina(bram_a_wr_data),
        .clkb(clk),
        .enb(1'b1),
        .addrb(bram_a_addr),
        .doutb(bram_a_dout)
    );

    BRAM_B bram_b (
        .clka(clk),
        .ena(1'b1),
        .wea(bram_b_wr_en),
        .addra(bram_b_wr_addr),
        .dina(bram_b_wr_data),
        .clkb(clk),
        .enb(1'b1),
        .addrb(bram_b_addr),
        .doutb(bram_b_dout)
    );

    BRAM_R bram_r (
        .clka(clk),
        .ena(1'b1),
        .wea(bram_r_wen),
        .addra(bram_r_addr),
        .dina(bram_r_din),
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
        .doutb(bram_ins_din)
    );

endmodule