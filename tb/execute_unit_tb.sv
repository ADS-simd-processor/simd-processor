`timescale 1ns / 1ps
`include "params.svh"

module execute_unit_tb;

    // Parameters
    parameter PE_COUNT = 4;
    parameter DATA_WIDTH = 8;

    // Testbench Signals
    logic clk, rstn;
    logic [PE_COUNT-1:0][DATA_WIDTH-1:0] a, b;
    logic [OP_SEL_WIDTH-1:0] pe_op;
    logic [1:0] dot_ctrl;
    logic [PE_COUNT-1:0][DATA_WIDTH-1:0] elem_out;
    logic [PE_COUNT-1:0][DATA_WIDTH-1:0] dot_out;
    logic half_clk;

    // Instantiate the DUT (Device Under Test)
    execute_unit #(
        .PE_COUNT(PE_COUNT),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (.*);

    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period
    end

    always_ff @(posedge clk) begin
        if (!rstn) 
            half_clk <= 0;
        else    
            half_clk <= half_clk ^ 1;
    end

    // Testbench Procedure
    initial begin
        // Initialize signals
        rstn = 0;
        a = '0;
        b = '0;
        pe_op = '0;
        dot_ctrl = 2'b00;

        // Apply reset
        #10 rstn = 1;

        // Test 1: pass B
        a = '{8'h01, 8'h02, 8'h03, 8'h04};
        b = '{8'h10, 8'h20, 8'h30, 8'h40};
        pe_op = 2'b00;
        #20;

        assert (elem_out == b) $display("Pass B successful"); 
        else begin
            $error("Pass B operation failed! Expected: %x, Got: %x", b, elem_out);
        end

        // Test 2: add operation
        pe_op = 2'b01;
        #20;

        // assert (elem_out == (a + b) & 8'hFFFFFFFF) $display("Addition successful"); 
        // else begin
        //     $error("Addition operation failed! Expected: %x, Got: %x", (a + b) & 8'hFFFFFFFF, elem_out);
        // end

        // Test 3: sub operation
        pe_op = 2'b10; 
        #20;

        // assert (elem_out == (a - b) & 8'hFFFFFFFF) $display("Sub successful"); 
        // else begin
        //     $error("Sub operation failed! Expected: %x, Got: %x", (a - b) & 8'hFFFFFFFF, elem_out);
        // end

        // Test 4: mul operation
        pe_op = 2'b11; 
        #20;

        // assert (elem_out == (a * b) & 8'hFFFFFFFF) $display("Mult successful"); 
        // else begin
        //     $error("Mult operation failed! Expected: %x, Got: %x", (a * b) & 8'hFFFFFFFF, elem_out);
        // end

        // Test 5: dot product
        a = '{8'h01, 8'h01, 8'h01, 8'h01};
        b = '{8'h01, 8'h01, 8'h01, 8'h01};
        pe_op = 2'b11; 
        dot_ctrl = 2'b11;
        #20;

        a = a * 2;
        b = b * 2;
        dot_ctrl = 2'b10;
        #20;

        a = '{8'h01, 8'h01, 8'h01, 8'h01};
        b = '{8'h01, 8'h01, 8'h01, 8'h01};
        pe_op = 2'b11; 
        dot_ctrl = 2'b01;
        #20;

        a = a * 2;
        b = b * 2;
        dot_ctrl = 2'b10;
        #20;

        a = '{8'h01, 8'h01, 8'h01, 8'h01};
        b = '{8'h01, 8'h01, 8'h01, 8'h01};
        pe_op = 2'b11; 
        dot_ctrl = 2'b01;
        #20;

        a = a * 2;
        b = b * 2;
        dot_ctrl = 2'b10;
        #20;

        a = '{8'h01, 8'h01, 8'h01, 8'h01};
        b = '{8'h01, 8'h01, 8'h01, 8'h01};
        pe_op = 2'b11; 
        dot_ctrl = 2'b01;
        #20;

        a = a * 2;
        b = b * 2;
        dot_ctrl = 2'b10;
        #20;

        dot_ctrl = 2'b00;
        // Finish simulation
        #10;
        $finish;
    end

endmodule
