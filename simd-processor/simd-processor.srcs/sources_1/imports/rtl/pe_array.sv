`include "params.svh"

module pe_array #(
    parameter PE_COUNT = 4,
    parameter DATA_WIDTH = 32
) (
    input logic clk, rstn,
    input logic [PE_COUNT-1:0][DATA_WIDTH-1:0] a, b,
    input logic [OP_SEL_WIDTH-1:0] pe_op,
    output logic [PE_COUNT-1:0][DATA_WIDTH-1:0] pe_out
);

    logic [PE_COUNT-1:0][DATA_WIDTH-1:0] c;

    genvar i;
    generate
        for (i = 0; i < PE_COUNT; i = i+1) begin
            pe #(
                .DATA_WIDTH(DATA_WIDTH)
            ) pe_unit (
                .a($signed(a[i])),
                .b($signed(b[i])),
                .op(pe_op),
                .c(c[i])
            );
        end
    endgenerate

    always_ff @( posedge clk ) begin 
        if (!rstn) begin
            pe_out <= 'b0;
        end
        else begin
            pe_out <= c;
        end
    end

endmodule