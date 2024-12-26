
`include "params.svh"

module datapath #(
    parameter PE_COUNT = 4,
    parameter DATA_WIDTH = 32,
    parameter BRAM_DEPTH = 1024,
    parameter ADDR_WIDTH = $clog2(BRAM_DEPTH)
) (
    input logic clk, rstn

    // TODO: add signals for connecting with BRAMs (instruction, A, B, result)
);

    localparam LOAD_CTRL_WIDTH = 3 * ADDR_WIDTH + 1 + OP_SEL_WIDTH + 1 + 1 + 1;
    localparam EXEC_CTRL_WIDTH = ADDR_WIDTH + 1 + OP_SEL_WIDTH + 1 + 1 + 1;
    localparam STORE_CTRL_WIDTH = ADDR_WIDTH + 1 + 1;

    // clock divider
    logic half_clk;

    // Initial control signals from decode
    logic [(OPCODE_WIDTH+ADDR_WIDTH*3+1)-1:0] instruction; //From ins mem
    logic pc; //Program counter

    logic [ADDR_WIDTH-1:0] a_addr, b_addr;
    logic [OP_SEL_WIDTH-1:0] pe_op;
    logic dot_prod_en; //enable dot product
    logic shift; //1- shift, 0- accumulate
    logic [ADDR_WIDTH-1:0] r_addr;
    logic write_en; //BRAM write enable
    logic r_select; // 0 - Write PE output, 1- write dot product output

    logic [LOAD_CTRL_WIDTH-1:0] load_ctrl_reg;
    logic [EXEC_CTRL_WIDTH-1:0] exec_ctrl_reg;
    logic [STORE_CTRL_WIDTH-1:0] store_ctrl_reg;

    // Load stage signals 
    logic [ADDR_WIDTH-1:0] load_a_addr, load_b_addr;

    // Execute stage signals 
    logic [OP_SEL_WIDTH-1:0] exec_pe_op;
    logic exec_dot_prod_en;  // Dot product enable 
    logic exec_shift;        // 1 = shift dot product output, 0 = accumulate

    // Store stage signals
    logic [ADDR_WIDTH-1:0] store_r_addr;
    logic store_write_en;     // BRAM write enable
    logic store_r_select;     // Which result to write (0 = PE output, 1 = dot product)

    // Intermediate signals
    logic [PE_COUNT-1:0][DATA_WIDTH-1:0] a, b, elem_out, dot_out, store_out;

    // Module instantiation

    decoder #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) decode (.*);

    execute_unit #(
        .PE_COUNT(PE_COUNT),
        .DATA_WIDTH(DATA_WIDTH)
    ) execute (
        .clk(clk),
        .rstn(rstn),
        .a(a),
        .b(b),
        .pe_op(exec_pe_op),
        .dot_prod_en(exec_dot_prod_en),
        .shift(exec_shift),
        .half_clk(half_clk),
        .elem_out(elem_out),
        .dot_out(dot_out)
    );

    // Combinational assignments
    assign store_out = (store_r_select) ? dot_out : elem_out;

    // Combinational control assignments
    assign {load_a_addr, load_b_addr} = load_ctrl_reg[EXEC_CTRL_WIDTH+:(2*ADDR_WIDTH)];
    assign {exec_pe_op, exec_dot_prod_en, exec_shift} = exec_ctrl_reg[STORE_CTRL_WIDTH+:(OP_SEL_WIDTH+2)];
    assign {store_r_addr, store_write_en, store_r_select} = store_ctrl_reg;

    // Half clock
    always_ff @(posedge clk) begin
        if (!rstn) 
            half_clk <= 0;
        else    
            half_clk <= half_clk ^ 1;
    end

    // Pipeline registers
    always_ff @( posedge clk ) begin 
        if (!rstn) begin
            load_ctrl_reg <= 'b0;
            exec_ctrl_reg <= 'b0;
            store_ctrl_reg <= 'b0;
        end
        else begin
            if (half_clk) begin
                load_ctrl_reg <= {a_addr, b_addr, pe_op, dot_prod_en, shift, r_addr, write_en, r_select};
                exec_ctrl_reg <= load_ctrl_reg[EXEC_CTRL_WIDTH-1:0];
                store_ctrl_reg <= exec_ctrl_reg[STORE_CTRL_WIDTH-1:0];
            end
        end
    end

endmodule