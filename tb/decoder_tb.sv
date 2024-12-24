module decoder_tb;

    // Parameters
    parameter ADDR_WIDTH = 10;
    parameter DATA_WIDTH = 32;
    parameter OPCODE_WIDTH = 3;
    parameter OP_SEL_WIDTH = 2;

    // Testbench signals
    logic [(OPCODE_WIDTH + ADDR_WIDTH * 3 + 1) - 1:0] instruction;
    logic [ADDR_WIDTH-1:0] a_addr, b_addr, r_addr;
    logic [OP_SEL_WIDTH-1:0] pe_op;
    logic dot_prod_en, shift, write_en, r_select;

    // Instantiate the DUT (Device Under Test)
    decoder #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .OPCODE_WIDTH(OPCODE_WIDTH),
        .OP_SEL_WIDTH(OP_SEL_WIDTH)
    ) dut (
        .instruction(instruction),
        .a_addr(a_addr),
        .b_addr(b_addr),
        .pe_op(pe_op),
        .dot_prod_en(dot_prod_en),
        .shift(shift),
        .r_addr(r_addr),
        .write_en(write_en),
        .r_select(r_select)
    );

    // Testbench logic
    initial begin
        // Monitor outputs
        $monitor("Time: %0t | instruction: %b | opcode: %b | a_addr: %b | b_addr: %b | r_addr: %b | pe_op: %b | dot_prod_en: %b | shift: %b | write_en: %b | r_select: %b",
                 $time, instruction, instruction[(OPCODE_WIDTH + ADDR_WIDTH * 3 + 1) - 1 -: OPCODE_WIDTH],
                 a_addr, b_addr, r_addr, pe_op, dot_prod_en, shift, write_en, r_select);

        // Test case 1: opcode = 000
        instruction = {3'b000, 10'd5, 10'd10, 10'd15, 1'b0}; 
        #10;

        // Test case 2: opcode = 001
        instruction = {3'b001, 10'd20, 10'd25, 10'd30, 1'b0}; 
        #10;

        // Test case 3: opcode = 010
        instruction = {3'b010, 10'd35, 10'd40, 10'd45, 1'b0};
        #10;

        // Test case 4: opcode = 011
        instruction = {3'b011, 10'd50, 10'd55, 10'd60, 1'b1};
        #10;

        // Test case 5: opcode = 100
        instruction = {3'b100, 10'd50, 10'd55, 10'd60, 1'b0};
        #10;
        // End simulation
        $finish;
    end

endmodule
