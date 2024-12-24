`include "params.svh"

module execute_unit #(
    parameter PE_COUNT = 4,
    parameter DATA_WIDTH = 32
) (
    input logic clk, rstn,
    input logic [PE_COUNT-1:0][DATA_WIDTH-1:0] a, b,

    // Control signals
    input logic [OP_SEL_WIDTH-1:0] pe_op,
    input logic dot_prod_en, shift,
    input logic half_clk,

    // Outputs
    output logic [PE_COUNT-1:0][DATA_WIDTH-1:0] elem_out,
    output logic [PE_COUNT-1:0][DATA_WIDTH-1:0] dot_out
);

    logic [PE_COUNT-1:0][DATA_WIDTH-1:0] pe_out;

    pe_array #(
        .PE_COUNT(PE_COUNT),
        .DATA_WIDTH(DATA_WIDTH)
    ) pe_array_unit (.*);

    dot_product #(
        .PE_COUNT(PE_COUNT),
        .DATA_WIDTH(DATA_WIDTH)
    ) dot_product_unit (
        .clk(clk),
        .rstn(rstn),
        .pe_res(pe_out),
        .dot_prod_en(half_clk & dot_prod_en),
        .shift(half_clk & shift),
        .dot_out(dot_out)
    );

    always_ff @(posedge clk) begin
        if (!rstn) begin
            elem_out <= 'b0;
        end
        else begin
            elem_out <= pe_out;
        end
    end

endmodule