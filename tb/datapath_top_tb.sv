`timescale 1ns / 1ps


module datapath_top_tb;

    parameter PE_COUNT = 4;
    parameter DATA_WIDTH = 32;
    parameter BRAM_DEPTH = 1024;
    parameter ADDR_WIDTH = $clog2(BRAM_DEPTH);
    parameter INS_ADDR_WIDTH = 11;
    parameter INS_WIDTH = 64;

    logic clk, rstn;
    logic stall, in_data_valid, out_data_valid;

    // BRAM A from PS
    logic bram_a_wr_en;
    logic [ADDR_WIDTH-1:0] bram_a_wr_addr;
    logic [PE_COUNT-1:0][DATA_WIDTH-1:0] bram_a_wr_data;

    // BRAM B from PS
    logic bram_b_wr_en;
    logic [ADDR_WIDTH-1:0] bram_b_wr_addr;
    logic [PE_COUNT-1:0][DATA_WIDTH-1:0] bram_b_wr_data;

    // BRAM INS from PS
    logic bram_ins_wr_en;
    logic [INS_ADDR_WIDTH-1:0] bram_ins_wr_addr;
    logic [INS_WIDTH-1:0] bram_ins_wr_data;

    // BRAM R from PS
    logic [INS_ADDR_WIDTH-1:0] bram_r_r_addr;
    // BRAM R to PS
    logic [PE_COUNT-1:0][DATA_WIDTH-1:0] bram_r_r_data;

    // Instantiate datapath_top
    datapath_top #(
        .PE_COUNT(PE_COUNT),
        .DATA_WIDTH(DATA_WIDTH),
        .BRAM_DEPTH(BRAM_DEPTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .INS_ADDR_WIDTH(INS_ADDR_WIDTH),
        .INS_WIDTH(INS_WIDTH)
    ) dut (
        .clk(clk),
        .rstn(rstn),
        .stall(stall),
        .in_data_valid(in_data_valid),
        .bram_a_wr_en(bram_a_wr_en),
        .bram_a_wr_addr(bram_a_wr_addr),
        .bram_a_wr_data(bram_a_wr_data),
        .bram_b_wr_en(bram_b_wr_en),
        .bram_b_wr_addr(bram_b_wr_addr),
        .bram_b_wr_data(bram_b_wr_data),
        .bram_ins_wr_en(bram_ins_wr_en),
        .bram_ins_wr_addr(bram_ins_wr_addr),
        .bram_ins_wr_data(bram_ins_wr_data),
        .bram_r_r_addr(bram_r_r_addr),
        .bram_r_r_data(bram_r_r_data),
        .out_data_valid(out_data_valid)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock
    end


    initial begin
        rstn = 0;
        stall = 0;
        bram_a_wr_en = 0;
        bram_b_wr_en = 0;
        bram_ins_wr_en = 0;
        bram_a_wr_addr = 0;
        bram_b_wr_addr = 0;
        bram_ins_wr_addr = 0;
        bram_a_wr_data = '0;
        bram_b_wr_data = '0;
        bram_ins_wr_data = '0;
        //bram_r_r_addr = 0;
        in_data_valid = 0;


        #10 rstn = 1;

        #400;
        @(posedge clk) stall = 1;

        #390;
        @(posedge clk) stall = 0;

        #41380

        in_data_valid = 1;
        // Read BRAM R 
        for (int i = 0; i < 50; i++) begin
            bram_r_r_addr =  i;
            #10; // Wait for 2 cycles 
            #10;

            $display("Address %d: Read Data Row: %d, %d, %d, %d", 
                     bram_r_r_addr, 
                     $signed(bram_r_r_data[0]),
                     $signed(bram_r_r_data[1]),
                     $signed(bram_r_r_data[2]),
                     $signed(bram_r_r_data[3]));
        end

        #50 $finish;
    end


endmodule
