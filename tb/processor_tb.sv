`timescale 1ns / 1ps

module processor_tb();

    parameter PE_COUNT = 4;
    parameter DATA_WIDTH = 32;
    parameter BRAM_DEPTH = 2048;
    parameter ADDR_WIDTH = $clog2(BRAM_DEPTH);
    parameter INS_ADDR_WIDTH = 11;
    parameter INS_WIDTH = 64;

    logic clk;
    logic in_data_valid;
    logic rstn;
    logic stall;
    logic out_data_valid;
    logic [ADDR_WIDTH-1:0] BRAM_PORTB_0_addr;
    logic BRAM_PORTB_0_clk, BRAM_PORTB_0_en;
    logic [PE_COUNT-1:0][DATA_WIDTH-1:0] BRAM_PORTB_0_dout;

    processor processor_uut(
        .clk(clk),
        .in_data_valid(in_data_valid),
        .rstn(rstn),
        .stall(stall),
        .out_data_valid(out_data_valid),
        .BRAM_PORTB_0_addr(BRAM_PORTB_0_addr),
        .BRAM_PORTB_0_clk(BRAM_PORTB_0_clk),
        .BRAM_PORTB_0_dout(BRAM_PORTB_0_dout),
        .BRAM_PORTB_0_en(BRAM_PORTB_0_en)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock
    end

    initial begin
        BRAM_PORTB_0_clk = 0;
        forever #5 BRAM_PORTB_0_clk = ~BRAM_PORTB_0_clk; // 100 MHz clock
    end

    assign BRAM_PORTB_0_en = 1;

    initial begin
        rstn = 0;
        stall = 0;
        in_data_valid = 0;


        #10 rstn = 1;
        #10 in_data_valid = 1;
        
        #20 in_data_valid = 0;

        wait (out_data_valid == 1);
        
        @(posedge clk);

        // Read BRAM R 
        for (int i = 0; i < 75; i++) begin
            BRAM_PORTB_0_addr =  i;
            #10; // Wait for 2 cycles 
            #10;

            $display("Address %d: Read Data Row: %d, %d, %d, %d", 
                     BRAM_PORTB_0_addr, 
                     $signed(BRAM_PORTB_0_dout[0]),
                     $signed(BRAM_PORTB_0_dout[1]),
                     $signed(BRAM_PORTB_0_dout[2]),
                     $signed(BRAM_PORTB_0_dout[3]));
        end
        
        in_data_valid = 1;

        #50 $finish;
    end


endmodule