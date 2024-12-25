module decoder_tb;

    // Parameters
    parameter INS_ADDR_WIDTH = 10;
    parameter ADDR_WIDTH = 10;
    parameter DATA_WIDTH = 32;
    parameter OPCODE_WIDTH = 3;
    parameter OP_SEL_WIDTH = 2;

    // Testbench signals
    logic clk, rstn, half_clk;
    logic [(OPCODE_WIDTH + ADDR_WIDTH * 3) - 1:0] instruction;
    logic [INS_ADDR_WIDTH-1:0] pc;
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
        .clk(clk),
        .rstn(rstn),
        .half_clk(half_clk),
        .instruction(instruction),
        .pc(pc),
        .a_addr(a_addr),
        .b_addr(b_addr),
        .pe_op(pe_op),
        .dot_prod_en(dot_prod_en),
        .shift(shift),
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

    // Testbench logic
    initial begin
        // Reset logic
        rstn = 0;
        #15 rstn = 1;  // Deassert reset after 15 time units

        // Monitor outputs
        $monitor("Time: %0t | instruction: %b | opcode: %b | pc: %b | a_addr: %b | b_addr: %b | r_addr: %b | pe_op: %b | dot_prod_en: %b | shift: %b | write_en: %b | r_select: %b",
                 $time, instruction, instruction[(OPCODE_WIDTH + ADDR_WIDTH * 3 ) - 1 -: OPCODE_WIDTH],
                 pc, a_addr, b_addr, r_addr, pe_op, dot_prod_en, shift, write_en, r_select);

        // Test case 1: opcode = 000
        instruction = {3'b000, 10'd5, 10'd10, 10'd15};
        #20;

        // Test case 2: opcode = 001
        instruction = {3'b001, 10'd20, 10'd25, 10'd30};
        #20;

        // Test case 3: opcode = 010
        instruction = {3'b010, 10'd35, 10'd40, 10'd45};
        #20;

        // Test case 4: opcode = 011
        instruction = {3'b011, 10'd50, 10'd55, 10'd60};
        #20;

        // Test case 5: opcode = 100
        instruction = {3'b100, 10'd50, 10'd55, 10'd60};
        #20;

        // Test case 6: opcode = 101
        instruction = {3'b101, 10'd50, 10'd55, 10'd60};
        #20;

        // End simulation
        $finish;
    end

endmodule
