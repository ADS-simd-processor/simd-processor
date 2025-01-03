
`include "params.svh"

module datapath #(
    parameter PE_COUNT = 4,
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 10,
    parameter BRAM_DEPTH = 1024,
    parameter INS_ADDR_WIDTH = 8,
    parameter INS_BRAM_WIDTH = 64
) (
    input logic clk, rstn,
    input logic stall,
        
    input logic in_data_valid,

    input logic [INS_BRAM_WIDTH-1:0] bram_ins_din, 
    input logic [PE_COUNT-1:0][DATA_WIDTH-1:0] bram_a_dout, 
    input logic [PE_COUNT-1:0][DATA_WIDTH-1:0] bram_b_dout,

    output logic [ADDR_WIDTH-1:0] bram_a_addr, bram_b_addr, bram_r_addr, 
    output logic bram_r_wen, //BRAM write enable     
    output logic [INS_ADDR_WIDTH-1:0] pc, //Program counter
    output logic [PE_COUNT-1:0][DATA_WIDTH-1:0] bram_r_din,

    output logic out_data_valid
);

    localparam LOAD_CTRL_WIDTH = 3 * ADDR_WIDTH + 1 + OP_SEL_WIDTH + 1 + 1 + 1;
    localparam EXEC_CTRL_WIDTH = ADDR_WIDTH + 1 + OP_SEL_WIDTH + 1 + 1 + 1;
    localparam STORE_CTRL_WIDTH = ADDR_WIDTH + 1 + 1;
    localparam INS_DATA_WIDTH = (OPCODE_WIDTH + ADDR_WIDTH*3);

    // clock divider
    logic half_clk;

    logic ins_valid;
    logic ins_done;

    // Initial control signals from decode
    logic [INS_DATA_WIDTH-1:0] instruction;
    logic [ADDR_WIDTH-1:0] a_addr, b_addr;
    logic [OP_SEL_WIDTH-1:0] pe_op;
    logic [1:0] dot_ctrl;
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
    logic [1:0] exec_dot_ctrl;

    // Store stage signals
    logic [ADDR_WIDTH-1:0] store_r_addr;
    logic store_write_en;     // BRAM write enable
    logic store_r_select;     // Which result to write (0 = PE output, 1 = dot product)

    // Intermediate signals
    logic [PE_COUNT-1:0][DATA_WIDTH-1:0] a, b, elem_out, dot_out, store_out;

    // Module instantiation

    decoder #(
        .INS_ADDR_WIDTH(INS_ADDR_WIDTH),
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
        .dot_ctrl(exec_dot_ctrl),
        .half_clk(half_clk),
        .elem_out(elem_out),
        .dot_out(dot_out)
    );

    status_manager sm(.*);

    // Combinational assignments
    assign instruction = bram_ins_din[INS_DATA_WIDTH-1:0];

    assign store_out = (store_r_select) ? dot_out : elem_out;

    // BRAM signals
    assign bram_a_addr = load_a_addr;
    assign bram_b_addr = load_b_addr;
    assign bram_r_addr = store_r_addr;
    assign a = bram_a_dout;
    assign b = bram_b_dout;
    assign bram_r_din = store_out;
    assign bram_r_wen = store_write_en;

    // Combinational control assignments
    assign {load_a_addr, load_b_addr} = load_ctrl_reg[EXEC_CTRL_WIDTH+:(2*ADDR_WIDTH)];
    assign {exec_pe_op, exec_dot_ctrl} = exec_ctrl_reg[STORE_CTRL_WIDTH+:(OP_SEL_WIDTH+2)];
    assign {store_r_addr, store_write_en, store_r_select} = store_ctrl_reg;

    assign load_ctrl_reg = {a_addr, b_addr, pe_op, dot_ctrl, r_addr, write_en, r_select};

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
            exec_ctrl_reg <= 'b0;
            store_ctrl_reg <= 'b0;
        end
        else begin
            if (half_clk) begin
                exec_ctrl_reg <= load_ctrl_reg[EXEC_CTRL_WIDTH-1:0];
                store_ctrl_reg <= exec_ctrl_reg[STORE_CTRL_WIDTH-1:0];
            end
        end
    end

endmodule