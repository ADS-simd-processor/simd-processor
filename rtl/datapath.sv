
`include "params.svh"

module datapath #(
    parameter PE_COUNT = 4,
    parameter DATA_WIDTH = 32,
    parameter BRAM_DEPTH = 1024,
    parameter ADDR_WIDTH = $clog2(BRAM_DEPTH)
) (
    input logic clk, rstn
);

    localparam LOAD_CTRL_WIDTH = 3 * ADDR_WIDTH + 1 + OP_SEL_WIDTH + 1 + 1 + 1;
    localparam EXEC_CTRL_WIDTH = ADDR_WIDTH + 1 + OP_SEL_WIDTH + 1 + 1 + 1;
    localparam STORE_CTRL_WIDTH = ADDR_WIDTH + 1 + 1;

    // clock divider
    logic half_clk;

    // Initial control signals from decode
    // TODO: add this after decoder module is made

    logic [LOAD_CTRL_WIDTH-1:0] load_ctrl_reg;
    logic [EXEC_CTRL_WIDTH-1:0] exec_ctrl_reg;
    logic [STORE_CTRL_WIDTH-1:0] store_ctrl_reg;

    // Load stage signals 
    logic [ADDR_WIDTH-1:0] a_addr, b_addr;

    // Execute stage signals 
    logic [OP_SEL_WIDTH-1:0] pe_op;
    logic dot_prod_en;  // Dot product enable 
    logic shift;        // 1 = shift dot product output, 0 = accumulate

    // Store stage signals
    logic [ADDR_WIDTH-1:0] r_addr;
    logic write_en;     // BRAM write enable
    logic r_select;     // Which result to write (0 = PE output, 1 = dot product)

    // Intermediate signals
    logic [PE_COUNT-1:0][DATA_WIDTH-1:0] a, b, elem_out, dot_out, store_out;

    // Module instantiation
    execute_unit #(
        .PE_COUNT(PE_COUNT),
        .DATA_WIDTH(DATA_WIDTH)
    ) execute (.*);

    // TODO: add load/store unit and decode unit

    // Combinational assignments
    assign store_out = (r_select) ? dot_out : elem_out;

    // Combinational control assignments
    assign {a_addr, b_addr} = load_ctrl_reg[EXEC_CTRL_WIDTH+:(2*ADDR_WIDTH)];
    assign {pe_op, dot_prod_en, shift} = exec_ctrl_reg[STORE_CTRL_WIDTH+:(OP_SEL_WIDTH+2)];
    assign {r_addr, write_en, r_select} = store_ctrl_reg;

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
                load_ctrl_reg <= 'b0;      // TODO: replace with decode control signals
                exec_ctrl_reg <= load_ctrl_reg[EXEC_CTRL_WIDTH-1:0];
                store_ctrl_reg <= exec_ctrl_reg[STORE_CTRL_WIDTH-1:0];
            end
        end
    end

endmodule