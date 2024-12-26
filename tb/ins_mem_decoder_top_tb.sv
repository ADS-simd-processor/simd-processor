module ins_mem_decoder_top_tb;

    parameter INS_ADDR_WIDTH = 8;
    parameter ADDR_WIDTH = 10;
    parameter DATA_WIDTH = 32;
    parameter OPCODE_WIDTH = 3;
    parameter OP_SEL_WIDTH = 2;
    parameter INS_WIDTH = 64;

    logic clk,rstn,half_clk;
    logic [ADDR_WIDTH-1:0] a_addr, b_addr, r_addr;
    logic [OP_SEL_WIDTH-1:0] pe_op;
    logic dot_prod_en, shift, write_en, r_select;
    logic [1:0] dot_ctrl;

    ins_mem_decoder_top #(
        .INS_ADDR_WIDTH(INS_ADDR_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .OPCODE_WIDTH(OPCODE_WIDTH),
        .OP_SEL_WIDTH(OP_SEL_WIDTH)
    ) uut(
        .clk(clk),
        .rstn(rstn),
        .half_clk(half_clk),
        .a_addr(a_addr),
        .b_addr(b_addr),
        .pe_op(pe_op),
        .dot_ctrl(dot_ctrl),
        .r_addr(r_addr),
        .write_en(write_en),
        .r_select(r_select)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10-unit clock period
    end

    // Half clock generation
    initial begin
        half_clk = 0;
        forever #10 half_clk = ~half_clk;  // 20-unit half clock period
    end

    initial begin
        // Reset logic
        rstn = 0;
        #10 rstn = 1;  // Deassert reset after 15 time units

        // Monitor outputs
        $monitor("Time: %0t | a_addr: %d | b_addr: %d | r_addr: %d | pe_op: %b | dot_prod_en: %b | shift: %b | write_en: %b | r_select: %b",
                 $time, a_addr, b_addr, r_addr, pe_op, dot_prod_en, shift, write_en, r_select);

        #200
        $finish;
    end

endmodule